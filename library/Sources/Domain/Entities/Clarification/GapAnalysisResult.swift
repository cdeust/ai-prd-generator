import Foundation

/// Generic gap analysis result with type parameters
///
/// Professional generic design - gap and question types are parameterized.
public struct GapAnalysisResult<CT, PT, GT>: Sendable, Codable
    where CT: Hashable & Codable & Sendable,
          PT: Comparable & Codable & Sendable & Hashable,
          GT: Hashable & Codable & Sendable
{
    /// Completeness score (0-1, higher = more complete)
    public let completenessScore: Double

    /// Detected information gaps
    public let detectedGaps: [GapType<GT>]

    /// Generated clarification questions
    public let questions: [ClarificationQuestion<CT, PT, GT>]

    /// Confidence in gap detection accuracy (0-1)
    public let confidence: Double

    public init(
        completenessScore: Double,
        detectedGaps: [GapType<GT>],
        questions: [ClarificationQuestion<CT, PT, GT>],
        confidence: Double
    ) {
        self.completenessScore = completenessScore
        self.detectedGaps = detectedGaps
        self.questions = questions
        self.confidence = confidence
    }

    /// Check if request is complete enough to proceed
    public func isCompleteEnough(threshold: Double = 0.9) -> Bool {
        completenessScore >= threshold
    }

    /// Get questions with priority above threshold
    public func questionsAbovePriority(_ threshold: QuestionPriority<PT>) -> [ClarificationQuestion<CT, PT, GT>] {
        questions.filter { $0.priority > threshold }
    }

    /// Get questions sorted by priority (descending)
    public func questionsByPriority() -> [ClarificationQuestion<CT, PT, GT>] {
        questions.sorted { $0.priority > $1.priority }
    }
}
