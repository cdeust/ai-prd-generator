import Foundation
import Domain

/// Calibrates reasoning confidence based on quality metrics
///
/// **Reusable Component:** Can be used in any multi-step reasoning system to adjust
/// confidence scores based on:
/// - Correction history (penalizes chains that needed fixes)
/// - Consistency across steps (rewards agreement)
/// - Assumption validation status (penalizes unvalidated claims)
///
/// Following Single Responsibility: Confidence calibration algorithm
public struct ConfidenceCalibrator: Sendable {
    /// Calibrate confidence score based on reasoning chain quality metrics
    ///
    /// - Parameters:
    ///   - hops: Chain of reasoning steps to analyze
    ///   - synthesisConfidence: Initial confidence from synthesis
    /// - Returns: Calibrated confidence score clamped between 0.3 and 0.98
    public func calibrate(
        hops: [ReasoningHop],
        synthesisConfidence: Double
    ) -> Double {
        let correctionPenalty = calculateCorrectionPenalty(hops: hops)
        let consistencyBonus = calculateConsistencyBonus(
            hops: hops,
            synthesisConfidence: synthesisConfidence
        )
        let assumptionPenalty = calculateAssumptionPenalty(hops: hops)

        let calibrated = synthesisConfidence - correctionPenalty + consistencyBonus - assumptionPenalty

        return clamp(calibrated)
    }

    private func calculateCorrectionPenalty(hops: [ReasoningHop]) -> Double {
        Double(hops.filter(\.wasCorrected).count) * 0.1
    }

    private func calculateConsistencyBonus(
        hops: [ReasoningHop],
        synthesisConfidence: Double
    ) -> Double {
        let avgHopConfidence = hops.map(\.confidence).reduce(0, +) / Double(hops.count)
        return abs(avgHopConfidence - synthesisConfidence) < 0.1 ? 0.05 : 0.0
    }

    private func calculateAssumptionPenalty(hops: [ReasoningHop]) -> Double {
        let totalAssumptions = hops.flatMap(\.assumptions)
        let unvalidatedRatio = Double(totalAssumptions.filter(\.requiresValidation).count) /
            Double(max(totalAssumptions.count, 1))
        return unvalidatedRatio * 0.15
    }

    private func clamp(_ value: Double) -> Double {
        max(0.3, min(0.98, value))
    }
}
