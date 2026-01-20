import Foundation
import Domain

/// Calculates quality metrics for verified thought chains
/// Following Single Responsibility: Quality metrics calculation only
struct QualityMetricsCalculator {
    /// Calculate comprehensive quality metrics
    func calculate(
        chain: VerifiedThoughtChain,
        reliabilityScore: Double
    ) -> QualityMetrics {
        QualityMetrics(
            hallucinationRisk: calculateHallucinationRisk(chain: chain),
            contextGrounding: calculateGroundingScore(chain: chain),
            logicalConsistency: calculateConsistencyScore(chain: chain),
            assumptionQuality: calculateAssumptionQuality(chain: chain),
            overallReliability: reliabilityScore
        )
    }

    private func calculateHallucinationRisk(chain: VerifiedThoughtChain) -> Double {
        let totalHops = Double(chain.hops.count)
        let correctedHops = Double(chain.hops.filter(\.wasCorrected).count)

        return correctedHops / max(totalHops, 1.0)
    }

    private func calculateGroundingScore(chain: VerifiedThoughtChain) -> Double {
        let correctionRatio = Double(chain.hops.filter(\.wasCorrected).count) /
            Double(max(chain.hops.count, 1))

        return 1.0 - correctionRatio
    }

    private func calculateConsistencyScore(chain: VerifiedThoughtChain) -> Double {
        let confidences = chain.hops.map(\.confidence)
        guard !confidences.isEmpty else { return 0.5 }

        let avg = confidences.reduce(0, +) / Double(confidences.count)
        let variance = confidences.map { pow($0 - avg, 2) }.reduce(0, +) / Double(confidences.count)

        return 1.0 - min(variance, 1.0)
    }

    private func calculateAssumptionQuality(chain: VerifiedThoughtChain) -> Double {
        guard !chain.assumptions.isEmpty else { return 1.0 }

        let avgConfidence = chain.assumptions
            .map(\.confidence)
            .reduce(0, +) / Double(chain.assumptions.count)

        let validatedRatio = Double(chain.assumptions.filter { !$0.requiresValidation }.count) /
            Double(chain.assumptions.count)

        return (avgConfidence + validatedRatio) / 2.0
    }
}
