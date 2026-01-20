import Foundation
import Domain

/// Single step in ReAct trajectory
public struct ReActStep: Identifiable, Sendable {
    public let id: UUID
    public let cycle: Int
    public let thought: Thought
    public let action: ReActAction
    public let actionResult: ReActActionResult
    public let timestamp: Date

    public init(
        id: UUID,
        cycle: Int,
        thought: Thought,
        action: ReActAction,
        actionResult: ReActActionResult,
        timestamp: Date
    ) {
        self.id = id
        self.cycle = cycle
        self.thought = thought
        self.action = action
        self.actionResult = actionResult
        self.timestamp = timestamp
    }
}
