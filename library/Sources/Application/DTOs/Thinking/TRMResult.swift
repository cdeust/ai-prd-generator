import Foundation
import Domain

/// Result of TRM (Tiny Recursion Model) reasoning
///
/// Encapsulates the complete outcome of recursive refinement,
/// including the final conclusion, confidence trajectory, and metadata.
///
/// **Properties:**
/// - `problem`: Original problem statement
/// - `refinementChain`: Complete refinement trajectory (all iterations)
/// - `conclusion`: Final refined prediction
/// - `confidence`: Final calibrated confidence score (0.0-1.0)
/// - `iterationsUsed`: Number of iterations performed
/// - `convergenceTrajectory`: Confidence scores across iterations
/// - `haltingReason`: Reason for stopping refinement
/// - `timestamp`: When refinement completed
///
/// **Usage:**
/// ```swift
/// let result = TRMResult(
///     problem: "What is 2+2?",
///     refinementChain: chain,
///     conclusion: "4",
///     confidence: 0.95,
///     iterationsUsed: 3,
///     convergenceTrajectory: [0.7, 0.85, 0.95],
///     haltingReason: "confidenceThresholdMet",
///     timestamp: Date()
/// )
/// ```
public struct TRMResult: Sendable {
    /// Original problem statement
    public let problem: String

    /// Complete refinement trajectory (all iterations)
    public let refinementChain: TRMRefinementChain

    /// Final refined prediction
    public let conclusion: String

    /// Final calibrated confidence score (0.0-1.0)
    public let confidence: Double

    /// Number of iterations performed
    public let iterationsUsed: Int

    /// Confidence scores across iterations (trajectory)
    public let convergenceTrajectory: [Double]

    /// Reason for stopping refinement
    public let haltingReason: String

    /// When refinement completed
    public let timestamp: Date

    public init(
        problem: String,
        refinementChain: TRMRefinementChain,
        conclusion: String,
        confidence: Double,
        iterationsUsed: Int,
        convergenceTrajectory: [Double],
        haltingReason: String,
        timestamp: Date
    ) {
        self.problem = problem
        self.refinementChain = refinementChain
        self.conclusion = conclusion
        self.confidence = confidence
        self.iterationsUsed = iterationsUsed
        self.convergenceTrajectory = convergenceTrajectory
        self.haltingReason = haltingReason
        self.timestamp = timestamp
    }
}
