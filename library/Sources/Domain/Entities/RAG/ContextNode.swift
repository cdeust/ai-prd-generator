import Foundation

/// Node in the context graph
/// Following Single Responsibility: Represents a context element
public struct ContextNode: Identifiable, Sendable {
    public let id: UUID
    public let type: ContextNodeType
    public let content: String
    public let confidence: Double  // 0.0-1.0
    public let metadata: [String: String]
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        type: ContextNodeType,
        content: String,
        confidence: Double = 0.7,
        metadata: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.confidence = confidence
        self.metadata = metadata
        self.timestamp = timestamp
    }
}
