import Foundation

/// Complete TRM refinement trajectory
/// Tracks full recursive refinement process
/// Following Single Responsibility: Represent complete refinement chain
public struct TRMRefinementChain: Identifiable, Sendable {
    public let id: UUID
    public let problem: String
    public let initialPrediction: String
    public let iterations: [TRMIteration]
    public let finalPrediction: String
    public let finalConfidence: Double
    public let haltedEarly: Bool
    public let totalIterations: Int
    public let convergenceTrajectory: [Double]
    public let timestamp: Date

    public init(
        id: UUID,
        problem: String,
        initialPrediction: String,
        iterations: [TRMIteration],
        finalPrediction: String,
        finalConfidence: Double,
        haltedEarly: Bool,
        totalIterations: Int,
        convergenceTrajectory: [Double],
        timestamp: Date
    ) {
        self.id = id
        self.problem = problem
        self.initialPrediction = initialPrediction
        self.iterations = iterations
        self.finalPrediction = finalPrediction
        self.finalConfidence = finalConfidence
        self.haltedEarly = haltedEarly
        self.totalIterations = totalIterations
        self.convergenceTrajectory = convergenceTrajectory
        self.timestamp = timestamp
    }

    /// Get best iteration by confidence
    public func bestIteration() -> TRMIteration? {
        iterations.max(by: { $0.confidence < $1.confidence })
    }

    /// Check if refinement converged successfully
    public func converged() -> Bool {
        finalConfidence > 0.9 || showsConvergence()
    }

    /// Detect convergence from trajectory
    private func showsConvergence() -> Bool {
        guard convergenceTrajectory.count >= 3 else {
            return false
        }

        let lastThree = Array(convergenceTrajectory.suffix(3))
        let variance = calculateVariance(lastThree)
        return variance < 0.05
    }

    /// Calculate variance of confidence scores
    private func calculateVariance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }

        let mean = values.reduce(0.0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0.0, +) / Double(values.count)
    }
}
