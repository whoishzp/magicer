import Foundation

// MARK: - Message role

enum CGRole: String, Codable {
    case ai
    case user
}

// MARK: - Delivery status

enum CGDeliveryStatus: String, Codable {
    case pending    // queued, AI hasn't consumed it yet
    case delivered  // AI has received the reply
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
    /// Delivery status for user messages (pending = queued, delivered = AI received)
    var deliveryStatus: CGDeliveryStatus?

    init(id: UUID = UUID(), role: CGRole, text: String,
         options: [String] = [], images: [String] = [],
         timestamp: Date = Date(),
         deliveryStatus: CGDeliveryStatus? = nil) {
        self.id             = id
        self.role           = role
        self.text           = text
        self.options        = options
        self.images         = images
        self.timestamp      = timestamp
        self.deliveryStatus = deliveryStatus
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
    /// Transient: true when new AI messages arrived while user was viewing another session.
    var hasUnread: Bool = false

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

    private enum CodingKeys: String, CodingKey {
        case id, topic, createdAt, updatedAt, messages
    }
}

// MARK: - Pending call (MCP response handler)

struct CGPendingCall {
    let callId: String
    let sessionId: String   // used to route user replies to the correct pending call
    let continuation: CheckedContinuation<CGFeedbackResult, Never>
}

// MARK: - Feedback result (returned to AI via MCP)

struct CGFeedbackResult {
    let text: String
    let images: [String]    // base64 PNG
}
