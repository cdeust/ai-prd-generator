import Foundation

/// Session metadata
/// Following Single Responsibility Principle - represents session metadata
public struct SessionMetadata: Codable, Sendable {
    public var title: String
    public var description: String
    public var tags: [String]
    public var messageCount: Int
    public var lastActivity: Date
    public var isActive: Bool

    public init(
        title: String = "New Session",
        description: String = "",
        tags: [String] = [],
        messageCount: Int = 0,
        lastActivity: Date = Date(),
        isActive: Bool = true
    ) {
        self.title = title
        self.description = description
        self.tags = tags
        self.messageCount = messageCount
        self.lastActivity = lastActivity
        self.isActive = isActive
    }
}
