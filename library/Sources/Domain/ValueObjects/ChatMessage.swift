import Foundation

/// Chat message for AI communication
public struct ChatMessage: Codable, Equatable, Sendable {
    public let role: ChatMessageRole
    public let content: String
    public let timestamp: Date?

    public init(role: ChatMessageRole, content: String, timestamp: Date? = nil) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    /// Validate chat message
    /// - Throws: ValidationError if content is invalid or timestamp is in future
    public func validate() throws {
        guard !content.isEmpty else {
            throw ValidationError.missingRequired(field: "content")
        }

        try validateContentLength()
        try validateTimestamp()
    }

    private func validateContentLength() throws {
        let maxLength = maxContentLength(for: role)

        guard content.count <= maxLength else {
            throw ValidationError.outOfRange(
                field: "content",
                min: "1",
                max: "\(maxLength)"
            )
        }
    }

    private func maxContentLength(for role: ChatMessageRole) -> Int {
        switch role {
        case .system: return 50_000
        case .user: return 100_000
        case .assistant: return 100_000
        }
    }

    private func validateTimestamp() throws {
        guard let timestamp = timestamp else { return }

        guard timestamp <= Date() else {
            throw ValidationError.custom(
                "Timestamp cannot be in the future"
            )
        }
    }
}

extension ChatMessage: CustomStringConvertible {
    public var description: String {
        "[\(role.rawValue)]: \(content.prefix(100))..."
    }
}
