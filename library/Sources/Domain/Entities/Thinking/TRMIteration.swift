import Foundation

/// Single iteration in TRM recursive refinement
/// Represents one cycle of latent state + prediction update
/// Following Single Responsibility: Track one refinement iteration
public struct TRMIteration: Identifiable, Sendable {
    public let id: UUID
    public let iterationNumber: Int
    public let latentState: RefinementState
    public let prediction: String
    public let confidence: Double
    public let improvementFromPrevious: Double
    public let reasoning: String
    public let timestamp: Date

    public init(
        id: UUID,
        iterationNumber: Int,
        latentState: RefinementState,
        prediction: String,
        confidence: Double,
        improvementFromPrevious: Double,
        reasoning: String,
        timestamp: Date
    ) {
        self.id = id
        self.iterationNumber = iterationNumber
        self.latentState = latentState
        self.prediction = prediction
        self.confidence = confidence
        self.improvementFromPrevious = improvementFromPrevious
        self.reasoning = reasoning
        self.timestamp = timestamp
    }

    /// Check if this iteration shows significant improvement
    public func hasSignificantImprovement() -> Bool {
        improvementFromPrevious > 0.05
    }

    /// Check if halting condition met
    public func shouldHalt(
        threshold: Double,
        maxIterations: Int
    ) -> Bool {
        confidence >= threshold || iterationNumber >= maxIterations
    }
}
