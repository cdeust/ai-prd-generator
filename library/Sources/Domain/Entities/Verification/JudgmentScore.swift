import Foundation

/// Evaluation score from a single LLM judge
/// Part of multi-judge consensus system
/// Following Single Responsibility: Represents one judge's evaluation
public struct JudgmentScore: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public let judgeProvider: String
    public let judgeModel: String
    public let score: Double
    public let confidence: Double
    public let reasoning: String
    public let verificationQuestionId: UUID
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        judgeProvider: String,
        judgeModel: String,
        score: Double,
        confidence: Double,
        reasoning: String,
        verificationQuestionId: UUID,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.judgeProvider = judgeProvider
        self.judgeModel = judgeModel
        self.score = score
        self.confidence = confidence
        self.reasoning = reasoning
        self.verificationQuestionId = verificationQuestionId
        self.timestamp = timestamp
    }

    /// Weighted score based on confidence
    /// Higher confidence = more influence on consensus
    public var weightedScore: Double {
        score * confidence
    }
}
