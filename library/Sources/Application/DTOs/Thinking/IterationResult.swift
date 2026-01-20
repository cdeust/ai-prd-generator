import Foundation
import Domain

/// Result of a single TRM refinement iteration
///
/// Encapsulates all outputs from one iteration cycle:
/// - The iteration record
/// - The refined prediction
/// - The new confidence score
/// - The updated latent state
///
/// **3R's Justification:**
/// - **Reliability**: Named fields prevent index confusion (vs tuple .0, .1, .2, .3)
/// - **Readability**: Self-documenting structure vs anonymous tuple
/// - **Reusability**: Can be used by monitoring, logging, or testing utilities
///
/// **Usage:**
/// ```swift
/// let result = IterationResult(
///     iteration: trmIteration,
///     prediction: "refined answer",
///     confidence: 0.85,
///     state: updatedState
/// )
/// print(result.prediction) // vs tuple.1
/// ```
public struct IterationResult: Sendable {
    /// The iteration record with full metadata
    public let iteration: TRMIteration

    /// The refined prediction text
    public let prediction: String

    /// The refined confidence score (0.0-1.0)
    public let confidence: Double

    /// The updated latent reasoning state
    public let state: RefinementState

    public init(
        iteration: TRMIteration,
        prediction: String,
        confidence: Double,
        state: RefinementState
    ) {
        self.iteration = iteration
        self.prediction = prediction
        self.confidence = confidence
        self.state = state
    }
}
