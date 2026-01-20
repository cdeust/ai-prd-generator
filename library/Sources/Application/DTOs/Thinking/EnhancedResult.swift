import Foundation
import Domain

/// Result of TRM-enhanced strategy execution
///
/// Wraps the final refined result with enhancement metadata.
public struct EnhancedResult<T: RefinableResult>: Sendable {
    /// The final refined result
    public let result: T

    /// Number of refinement iterations performed
    public let iterationsPerformed: Int

    /// Whether refinement converged
    public let converged: Bool

    /// Whether refinement was halted due to oscillation
    public let haltedOnOscillation: Bool

    /// Whether refinement was halted due to diminishing returns
    public let haltedOnDiminishingReturns: Bool

    /// Confidence improvement from initial to final
    public let confidenceImprovement: Double

    public init(
        result: T,
        iterationsPerformed: Int,
        converged: Bool,
        haltedOnOscillation: Bool,
        haltedOnDiminishingReturns: Bool,
        confidenceImprovement: Double
    ) {
        self.result = result
        self.iterationsPerformed = iterationsPerformed
        self.converged = converged
        self.haltedOnOscillation = haltedOnOscillation
        self.haltedOnDiminishingReturns = haltedOnDiminishingReturns
        self.confidenceImprovement = confidenceImprovement
    }
}
