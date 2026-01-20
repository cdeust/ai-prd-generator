import Foundation

/// Confidence assessment for gap resolution attempts.
///
/// Tracks the confidence score, reasoning, and supporting evidence for a resolution attempt.
/// Used to determine whether to auto-apply a resolution, present it with caveats, or ask the user.
public struct ResolutionConfidence: Codable, Sendable, Equatable {
    /// Confidence score (0.0 - 1.0)
    /// - 0.90-1.00: Very high confidence - auto-apply
    /// - 0.70-0.89: High confidence - present with caveat
    /// - 0.40-0.69: Medium confidence - consider asking user
    /// - 0.00-0.39: Low confidence - ask user or skip
    public let score: Double

    /// Reasoning explaining the confidence level
    public let reasoning: String

    /// Evidence sources supporting the resolution
    public let sources: [EvidenceSource]

    /// Timestamp when confidence was assessed
    public let assessedAt: Date

    public init(
        score: Double,
        reasoning: String,
        sources: [EvidenceSource],
        assessedAt: Date = Date()
    ) {
        self.score = Self.clamp(score, min: 0.0, max: 1.0)
        self.reasoning = reasoning
        self.sources = sources
        self.assessedAt = assessedAt
    }

    /// Confidence level category
    public var level: ConfidenceLevel {
        switch score {
        case 0.90...1.00:
            return .veryHigh
        case 0.70..<0.90:
            return .high
        case 0.40..<0.70:
            return .medium
        case 0.00..<0.40:
            return .low
        default:
            return .low
        }
    }

    /// Whether this confidence level supports automatic resolution
    public var supportsAutoResolution: Bool {
        score >= 0.70
    }

    /// Whether this resolution should be presented to user for review
    public var requiresUserReview: Bool {
        score < 0.90 && score >= 0.40
    }

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }
}
