import Foundation
import Domain

/// A question with its coherence and effectiveness scores
/// Used for tracking and filtering clarification questions before asking
public struct ScoredQuestion: Sendable {
    public let question: ClarificationQuestion<String, Int, String>
    public let coherenceScore: Double       // Is this relevant to the product? (threshold: 0.9)
    public let effectivenessScore: Double   // Measured against feature description (threshold: 0.8)
    public let reasoning: String

    public init(
        question: ClarificationQuestion<String, Int, String>,
        coherenceScore: Double,
        effectivenessScore: Double,
        reasoning: String
    ) {
        self.question = question
        self.coherenceScore = coherenceScore
        self.effectivenessScore = effectivenessScore
        self.reasoning = reasoning
    }

    public var overallScore: Double {
        (coherenceScore + effectivenessScore) / 2.0
    }
}
