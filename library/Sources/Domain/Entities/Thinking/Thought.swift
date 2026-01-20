import Foundation

/// Individual thought in reasoning chain
/// Following Single Responsibility: Represents one thought step only
public struct Thought: Identifiable, Sendable, Codable {
    public let id: UUID
    public let content: String
    public let step: Int
    public let type: ThoughtType
    public let confidence: Double

    public init(
        id: UUID = UUID(),
        content: String,
        step: Int,
        type: ThoughtType,
        confidence: Double = 0.5
    ) {
        self.id = id
        self.content = content
        self.step = step
        self.type = type
        self.confidence = max(0.0, min(1.0, confidence))
    }
}
