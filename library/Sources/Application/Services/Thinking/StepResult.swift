import Foundation

/// Result of executing a plan step
public struct StepResult: Identifiable, Sendable {
    public let id: UUID
    public let stepId: UUID
    public let stepNumber: Int
    public let output: String
    public let reasoning: String
    public let confidence: Double
    public let completedAt: Date

    public init(
        id: UUID,
        stepId: UUID,
        stepNumber: Int,
        output: String,
        reasoning: String,
        confidence: Double,
        completedAt: Date
    ) {
        self.id = UUID()
        self.stepId = stepId
        self.stepNumber = stepNumber
        self.output = output
        self.reasoning = reasoning
        self.confidence = confidence
        self.completedAt = completedAt
    }
}
