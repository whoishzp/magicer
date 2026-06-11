import Foundation
import AppKit

/// Manages all CursorGood sessions: routing, persistence, and live state.
@MainActor
final class CGSessionManager: ObservableObject {
    static let shared = CGSessionManager()

    @Published var sessions: [CGSession] = []       // ordered by updatedAt desc
    @Published var selectedSessionId: String? = nil

    /// Per-session draft text preserved across session switches
    var draftTexts: [String: String] = [:]

    /// callId → pending continuation (one per in-flight MCP call)
    private var pendingCalls: [String: CGPendingCall] = [:]
    /// session_id → debounce task (50 ms merge window)
    private var debounceTimers: [String: Task<Void, Never>] = [:]
    /// session_id → queued user inputs while no pending call exists
    private var queuedInputs: [String: [CGFeedbackResult]] = [:]

    // MARK: - Storage

    nonisolated private static var storageDir: URL {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cursor/data/one/cursorgood", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    nonisolated private func storageURL(for sessionId: String) -> URL {
        CGSessionManager.storageDir
            .appendingPathComponent("\(CGSessionManager.sanitizeSessionId(sessionId)).json")
    }

    /// Sanitize session_id: only allow alphanumerics, hyphen, underscore, dot to prevent path traversal.
    nonisolated private static func sanitizeSessionId(_ id: String) -> String {
        let safe = id.unicodeScalars.filter { CharacterSet.alphanumerics.union(.init(charactersIn: "-_.")).contains($0) }
        let result = String(safe)
        return result.isEmpty ? UUID().uuidString : String(result.prefix(128))
    }

    func loadAll() {
        Task.detached(priority: .background) { [weak self] in
            let dir = CGSessionManager.storageDir
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil)
            else { return }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var loaded: [CGSession] = files
                .filter { $0.pathExtension == "json" }
                .compactMap { try? decoder.decode(CGSession.self, from: Data(contentsOf: $0)) }
            loaded.sort { $0.updatedAt > $1.updatedAt }

            await MainActor.run { self?.sessions = loaded }
        }
    }

    private func save(_ session: CGSession) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(session) {
            try? data.write(to: storageURL(for: session.id))
        }
    }

    // MARK: - Session Routing

    func session(for id: String, topic: String = "") -> CGSession {
        if let existing = sessions.first(where: { $0.id == id }) {
            return existing
        }
        let new = CGSession(id: id, topic: topic)
        sessions.insert(new, at: 0)
        save(new)
        return new
    }

    private func updateSession(_ updated: CGSession) {
        if let idx = sessions.firstIndex(where: { $0.id == updated.id }) {
            sessions[idx] = updated
            sessions.sort { $0.updatedAt > $1.updatedAt }
        }
        save(updated)
    }

    // MARK: - Receiving AI messages

    /// Called by the MCP server when an AI call arrives.
    /// Returns the user's reply (may block until user responds).
    func promptUser(callId: String,
                    sessionId: String,
                    sessionTopic: String,
                    message: String,
                    options: [String]) async -> CGFeedbackResult {

        // Consume all buffered user inputs for this session, merge into one reply
        if let queued = queuedInputs.removeValue(forKey: sessionId), !queued.isEmpty {
            let mergedText = queued.map(\.text).filter { !$0.isEmpty }.joined(separator: "\n")
            let mergedImages = queued.flatMap(\.images)
            markPendingMessagesDelivered(sessionId: sessionId)
            return CGFeedbackResult(text: mergedText, images: mergedImages)
        }

        // Update session with AI message
        var s = session(for: sessionId, topic: sessionTopic)
        if !sessionTopic.isEmpty && s.topic != sessionTopic { s.topic = sessionTopic }
        s.messages.append(CGMessage(role: .ai, text: message, options: options))
        s.updatedAt = Date()
        updateSession(s)

        // Smart session switching: don't steal focus if user is viewing another session
        let windowIsVisible = isWindowVisible()
        if !windowIsVisible || selectedSessionId == nil {
            selectedSessionId = sessionId
            surfaceWindow()
        } else if selectedSessionId == sessionId {
            surfaceWindow()
        } else {
            // Window open + user viewing different session → mark unread, don't switch
            if let idx = sessions.firstIndex(where: { $0.id == sessionId }) {
                sessions[idx].hasUnread = true
            }
        }

        // Await user reply
        return await withCheckedContinuation { cont in
            let call = CGPendingCall(callId: callId, sessionId: sessionId, continuation: cont)
            pendingCalls[callId] = call
        }
    }

    // MARK: - User submitting a reply

    func submitReply(sessionId: String, text: String, images: [String]) {
        var s = session(for: sessionId)

        // Resolve the first pending call that belongs to this session
        if let callId = pendingCalls.values.first(where: { $0.sessionId == sessionId })?.callId,
           let call = pendingCalls.removeValue(forKey: callId) {
            s.messages.append(CGMessage(role: .user, text: text, images: images, deliveryStatus: .delivered))
            s.updatedAt = Date()
            updateSession(s)
            debounceTimers[sessionId]?.cancel()
            debounceTimers[sessionId] = nil
            call.continuation.resume(returning: CGFeedbackResult(text: text, images: images))
        } else {
            s.messages.append(CGMessage(role: .user, text: text, images: images, deliveryStatus: .pending))
            s.updatedAt = Date()
            updateSession(s)
            queuedInputs[sessionId, default: []].append(
                CGFeedbackResult(text: text, images: images))
        }
    }

    // MARK: - Delete session

    func deleteSession(id: String) {
        // Cancel any pending continuations to avoid Swift runtime "continuation not resumed" warnings
        let stale = pendingCalls.filter { $0.value.sessionId == id }
        for (callId, call) in stale {
            call.continuation.resume(returning: CGFeedbackResult(text: "", images: []))
            pendingCalls.removeValue(forKey: callId)
        }
        queuedInputs.removeValue(forKey: id)

        sessions.removeAll { $0.id == id }
        try? FileManager.default.removeItem(at: storageURL(for: id))
        if selectedSessionId == id { selectedSessionId = sessions.first?.id }
    }

    // MARK: - Pending badge

    var hasPendingCalls: Bool { !pendingCalls.isEmpty }

    func hasPendingCall(for sessionId: String) -> Bool {
        pendingCalls.values.contains { $0.sessionId == sessionId }
    }

    // MARK: - Delivery status

    private func markPendingMessagesDelivered(sessionId: String) {
        guard let idx = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        var changed = false
        for i in sessions[idx].messages.indices {
            if sessions[idx].messages[i].deliveryStatus == .pending {
                sessions[idx].messages[i].deliveryStatus = .delivered
                changed = true
            }
        }
        if changed { save(sessions[idx]) }
    }

    // MARK: - Unread management

    func markRead(sessionId: String) {
        if let idx = sessions.firstIndex(where: { $0.id == sessionId }), sessions[idx].hasUnread {
            sessions[idx].hasUnread = false
        }
    }

    // MARK: - Window surface helper

    private func isWindowVisible() -> Bool {
        NSApp.windows.contains { $0.isVisible && $0.title == "ONE" }
    }

    private func surfaceWindow() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: .openCursorGoodPanel, object: nil)
        }
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let openCursorGoodPanel = Notification.Name("openCursorGoodPanel")
}
