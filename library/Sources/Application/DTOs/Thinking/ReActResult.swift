import Foundation

/// Final ReAct result
public struct ReActResult: Sendable {
    public let task: String
    public let trajectory: [ReActStep]
    public let conclusion: String
    public let totalCycles: Int
    public let finalContext: String

    public init(
        task: String,
        trajectory: [ReActStep],
        conclusion: String,
        totalCycles: Int,
        finalContext: String
    ) {
        self.task = task
        self.trajectory = trajectory
        self.conclusion = conclusion
        self.totalCycles = totalCycles
        self.finalContext = finalContext
    }
}
