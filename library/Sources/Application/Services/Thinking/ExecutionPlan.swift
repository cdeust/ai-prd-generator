import Foundation

/// Execution plan with ordered steps
public struct ExecutionPlan: Identifiable, Sendable {
    public let id: UUID
    public let problem: String
    public let steps: [PlanStep]
    public let createdAt: Date

    public init(
        id: UUID,
        problem: String,
        steps: [PlanStep],
        createdAt: Date
    ) {
        self.id = id
        self.problem = problem
        self.steps = steps
        self.createdAt = createdAt
    }
}
