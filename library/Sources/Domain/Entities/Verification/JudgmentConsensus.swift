import Foundation

/// Consensus result from multiple LLM judges
/// Combines individual judgments into unified decision
/// Following Single Responsibility: Represents aggregated judgment
public struct JudgmentConsensus: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public let verificationQuestionId: UUID
    public let individualScores: [JudgmentScore]
    public let consensusScore: Double
    public let consensusConfidence: Double
    public let agreementLevel: AgreementLevel
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        verificationQuestionId: UUID,
        individualScores: [JudgmentScore],
        consensusScore: Double,
        consensusConfidence: Double,
        agreementLevel: AgreementLevel,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.verificationQuestionId = verificationQuestionId
        self.individualScores = individualScores
        self.consensusScore = consensusScore
        self.consensusConfidence = consensusConfidence
        self.agreementLevel = agreementLevel
        self.timestamp = timestamp
    }

    /// Whether judges reached strong consensus
    /// Strong consensus = high agreement + high confidence
    public var hasStrongConsensus: Bool {
        agreementLevel == .high && consensusConfidence > 0.8
    }

    /// Standard deviation of judge scores
    /// Lower = more agreement among judges
    public var scoreVariance: Double {
        guard !individualScores.isEmpty else { return 0.0 }

        let mean = individualScores.map(\.score).reduce(0, +) / Double(individualScores.count)
        let squaredDiffs = individualScores.map { pow($0.score - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(individualScores.count)

        return sqrt(variance)
    }
}
