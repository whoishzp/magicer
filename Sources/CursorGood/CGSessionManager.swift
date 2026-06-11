import Foundation
import AppKit

/// Manages all CursorGood sessions: routing, persistence, and live state.
@MainActor
final class CGSessionManager: ObservableObject {
    static let shared = CGSessionManager()

    @Published var sessions: [CGSession] = []       // ordered by updatedAt desc
    @Published var selectedSessionId: String? = nil

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

        // Consume any buffered user input for this session (sent before AI called)
        if var queued = queuedInputs[sessionId], !queued.isEmpty {
            let first = queued.removeFirst()
            queuedInputs[sessionId] = queued.isEmpty ? nil : queued
            return first
        }

        // Update session with AI message
        var s = session(for: sessionId, topic: sessionTopic)
        if !sessionTopic.isEmpty && s.topic != sessionTopic { s.topic = sessionTopic }
        s.messages.append(CGMessage(role: .ai, text: message, options: options))
        s.updatedAt = Date()
        updateSession(s)

        // Auto-select & surface the window
        selectedSessionId = sessionId
        surfaceWindow()

        // Await user reply
        return await withCheckedContinuation { cont in
            let call = CGPendingCall(callId: callId, sessionId: sessionId, continuation: cont)
            pendingCalls[callId] = call
        }
    }

    // MARK: - User submitting a reply

    func submitReply(sessionId: String, text: String, images: [String]) {
        var s = session(for: sessionId)
        s.messages.append(CGMessage(role: .user, text: text, images: images))
        s.updatedAt = Date()
        updateSession(s)

        // Resolve the first pending call that belongs to this session
        if let callId = pendingCalls.values.first(where: { $0.sessionId == sessionId })?.callId,
           let call = pendingCalls.removeValue(forKey: callId) {
            debounceTimers[sessionId]?.cancel()
            debounceTimers[sessionId] = nil
            call.continuation.resume(returning: CGFeedbackResult(text: text, images: images))
        } else {
            // No pending call — buffer for next AI request
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

    // MARK: - Window surface helper

    private func surfaceWindow() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            // AppDelegate will handle switching to the CursorGood tab via notification
            NotificationCenter.default.post(name: .openCursorGoodPanel, object: nil)
        }
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let openCursorGoodPanel = Notification.Name("openCursorGoodPanel")
}
