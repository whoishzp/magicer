import Foundation

// MARK: - Message role

enum CGRole: String, Codable {
    case ai
    case user
}

// MARK: - Chat message

struct CGMessage: Codable, Identifiable, Equatable {
    var id: UUID
    var role: CGRole
    var text: String
    /// Predefined option buttons shown with AI messages.
    var options: [String]
    /// Base64-encoded PNG strings attached by the user.
    var images: [String]
    var timestamp: Date

    init(id: UUID = UUID(), role: CGRole, text: String,
         options: [String] = [], images: [String] = [],
         timestamp: Date = Date()) {
        self.id        = id
        self.role      = role
        self.text      = text
        self.options   = options
        self.images    = images
        self.timestamp = timestamp
    }
}

// MARK: - Session

struct CGSession: Codable, Identifiable, Equatable {
    /// Matches the session_id passed by the AI caller.
    var id: String
    /// Human-readable topic passed via session_topic.
    var topic: String
    var createdAt: Date
    var updatedAt: Date
    var messages: [CGMessage]

    init(id: String, topic: String = "", createdAt: Date = Date()) {
        self.id        = id
        self.topic     = topic
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.messages  = []
    }

    var displayTitle: String {
        topic.isEmpty ? "未命名会话" : topic
    }
}

// MARK: - Pending call (MCP response handler)

struct CGPendingCall {
    let callId: String
    let continuation: CheckedContinuation<CGFeedbackResult, Never>
}

// MARK: - Feedback result (returned to AI via MCP)

struct CGFeedbackResult {
    let text: String
    let images: [String]    // base64 PNG
}
