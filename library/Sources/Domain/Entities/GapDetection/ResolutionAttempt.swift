import Foundation

/// A single attempt to resolve an information gap.
///
/// Tracks the strategy used, the result obtained, confidence level, and supporting evidence.
/// Multiple resolution attempts can be made for a single gap using different strategies.
public struct ResolutionAttempt: Codable, Sendable, Identifiable, Equatable {
    /// Unique identifier for this attempt
    public let id: UUID

    /// Strategy used for this resolution attempt
    public let strategy: ResolutionStrategy

    /// The resolved answer or information
    public let result: ResolutionResult

    /// Confidence in this resolution
    public let confidence: ResolutionConfidence

    /// Supporting evidence for the resolution
    public let evidence: [EvidenceSource]

    /// When this attempt was made
    public let attemptedAt: Date

    /// Duration of the resolution attempt
    public let duration: TimeInterval?

    public init(
        id: UUID = UUID(),
        strategy: ResolutionStrategy,
        result: ResolutionResult,
        confidence: ResolutionConfidence,
        evidence: [EvidenceSource] = [],
        attemptedAt: Date = Date(),
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.strategy = strategy
        self.result = result
        self.confidence = confidence
        self.evidence = evidence
        self.attemptedAt = attemptedAt
        self.duration = duration
    }

    /// Whether this attempt was successful
    public var isSuccessful: Bool {
        switch result {
        case .success:
            return true
        case .failure, .inconclusive:
            return false
        }
    }

    /// Whether this resolution meets the confidence threshold
    public func meetsConfidenceThreshold(_ threshold: Double) -> Bool {
        confidence.score >= threshold
    }
}
