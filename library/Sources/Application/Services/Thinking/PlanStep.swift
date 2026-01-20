import Foundation

/// Single step in execution plan
public struct PlanStep: Identifiable, Sendable {
    public let id: UUID
    public let stepNumber: Int
    public let description: String
    public let requirements: String
    public let expectedOutput: String
    public let potentialChallenges: String

    public init(
        id: UUID,
        stepNumber: Int,
        description: String,
        requirements: String,
        expectedOutput: String,
        potentialChallenges: String
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.description = description
        self.requirements = requirements
        self.expectedOutput = expectedOutput
        self.potentialChallenges = potentialChallenges
    }
}
