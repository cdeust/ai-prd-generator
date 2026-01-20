import Foundation

/// Session entity for tracking AI conversations
/// Following Single Responsibility Principle - represents conversation session
public struct Session: Identifiable, Codable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let startTime: Date
    public var endTime: Date?
    public var messages: [ChatMessage]
    public var metadata: SessionMetadata
    public var prdDocumentId: UUID?

    public init(
        id: UUID = UUID(),
        userId: UUID,
        startTime: Date = Date(),
        messages: [ChatMessage] = [],
        metadata: SessionMetadata = SessionMetadata(),
        prdDocumentId: UUID? = nil
    ) {
        self.id = id
        self.userId = userId
        self.startTime = startTime
        self.endTime = nil
        self.messages = messages
        self.metadata = metadata
        self.prdDocumentId = prdDocumentId
    }

    public mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        metadata.messageCount = messages.count
        metadata.lastActivity = Date()
    }

    public mutating func end() {
        endTime = Date()
        metadata.isActive = false
    }
}
