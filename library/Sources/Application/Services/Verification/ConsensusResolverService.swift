import Foundation
import Domain

/// Service to resolve consensus from multiple judge scores
/// Combines individual judgments using weighted voting
/// Following Single Responsibility: Only resolves consensus
public struct ConsensusResolverService {
    public init() {}

    /// Resolve consensus from multiple judge scores
    /// Uses weighted average based on confidence
    /// - Parameters:
    ///   - scores: Individual judge scores
    ///   - verificationQuestionId: ID of verification question
    /// - Returns: Consensus result
    public func resolveConsensus(
        scores: [JudgmentScore],
        verificationQuestionId: UUID
    ) -> JudgmentConsensus {
        guard !scores.isEmpty else {
            return JudgmentConsensus(
                verificationQuestionId: verificationQuestionId,
                individualScores: [],
                consensusScore: 0.0,
                consensusConfidence: 0.0,
                agreementLevel: .low
            )
        }

        let consensusScore = calculateWeightedScore(scores)
        let consensusConfidence = calculateAverageConfidence(scores)
        let scoreVariance = calculateScoreVariance(scores)
        let agreementLevel = AgreementLevel.from(scoreVariance: scoreVariance)

        return JudgmentConsensus(
            verificationQuestionId: verificationQuestionId,
            individualScores: scores,
            consensusScore: consensusScore,
            consensusConfidence: consensusConfidence,
            agreementLevel: agreementLevel
        )
    }

    /// Resolve consensus WITH disagreement handling
    /// Analyzes disagreement patterns and recommends actions
    /// - Parameters:
    ///   - scores: Individual judge scores
    ///   - verificationQuestionId: ID of verification question
    /// - Returns: Consensus and resolution strategy
    public func resolveConsensusWithDisagreement(
        scores: [JudgmentScore],
        verificationQuestionId: UUID
    ) -> (consensus: JudgmentConsensus, resolution: DisagreementResolution) {
        let consensus = resolveConsensus(
            scores: scores,
            verificationQuestionId: verificationQuestionId
        )

        let resolution = analyzeDisagreement(consensus: consensus, scores: scores)

        return (consensus, resolution)
    }

    /// Analyze disagreement and determine resolution strategy
    private func analyzeDisagreement(
        consensus: JudgmentConsensus,
        scores: [JudgmentScore]
    ) -> DisagreementResolution {
        switch consensus.agreementLevel {
        case .high:
            return .accept(
                score: consensus.consensusScore,
                confidence: consensus.consensusConfidence
            )

        case .medium:
            return handleMediumAgreement(consensus: consensus)

        case .low:
            return handleLowAgreement(consensus: consensus, scores: scores)
        }
    }

    private func handleMediumAgreement(
        consensus: JudgmentConsensus
    ) -> DisagreementResolution {
        if consensus.consensusScore < 0.6 {
            return .flagForReview(concerns: [
                "Moderate judge agreement with low score",
                "Score: \(String(format: "%.2f", consensus.consensusScore))",
                "Variance: \(String(format: "%.2f", consensus.scoreVariance))"
            ])
        } else {
            return .accept(
                score: consensus.consensusScore * 0.95,
                confidence: consensus.consensusConfidence * 0.9
            )
        }
    }

    private func handleLowAgreement(
        consensus: JudgmentConsensus,
        scores: [JudgmentScore]
    ) -> DisagreementResolution {
        let highScoreCount = scores.filter { $0.score >= 0.7 }.count
        let lowScoreCount = scores.filter { $0.score < 0.4 }.count
        let mediumScoreCount = scores.count - highScoreCount - lowScoreCount

        if highScoreCount >= 3 && lowScoreCount <= 1 {
            return .accept(
                score: consensus.consensusScore * 0.85,
                confidence: consensus.consensusConfidence * 0.7
            )
        } else if lowScoreCount >= 3 {
            return .reject(
                reason: "Majority (\(lowScoreCount)/\(scores.count)) scored low with disagreement"
            )
        } else if mediumScoreCount >= scores.count / 2 {
            return .reEvaluate(
                reason: "Mixed scores - no clear consensus"
            )
        } else {
            return .flagForReview(concerns: [
                "Significant disagreement",
                "High: \(highScoreCount), Med: \(mediumScoreCount), Low: \(lowScoreCount)",
                "Variance: \(String(format: "%.2f", consensus.scoreVariance))"
            ])
        }
    }

    private func calculateWeightedScore(_ scores: [JudgmentScore]) -> Double {
        let totalWeight = scores.map(\.confidence).reduce(0, +)

        guard totalWeight > 0 else {
            return scores.map(\.score).reduce(0, +) / Double(scores.count)
        }

        let weightedSum = scores
            .map { $0.score * $0.confidence }
            .reduce(0, +)

        return weightedSum / totalWeight
    }

    private func calculateAverageConfidence(_ scores: [JudgmentScore]) -> Double {
        guard !scores.isEmpty else { return 0.0 }

        return scores.map(\.confidence).reduce(0, +) / Double(scores.count)
    }

    private func calculateScoreVariance(_ scores: [JudgmentScore]) -> Double {
        guard scores.count > 1 else { return 0.0 }

        let mean = scores.map(\.score).reduce(0, +) / Double(scores.count)
        let squaredDiffs = scores.map { pow($0.score - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(scores.count)

        return sqrt(variance)
    }
}
