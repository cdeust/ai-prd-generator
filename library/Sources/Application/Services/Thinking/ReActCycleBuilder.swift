import Foundation
import Domain

/// Builds ReAct reasoning-action cycles
/// Single Responsibility: Build and parse thought-action cycles
public struct ReActCycleBuilder: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Generate next thought and action
    public func nextCycle(
        task: String,
        context: String,
        trajectory: [ReActStep],
        cycle: Int
    ) async throws -> (Thought, ReActAction) {
        let prompt = buildPrompt(
            task: task,
            context: context,
            trajectory: trajectory,
            cycle: cycle
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.3
        )

        return parseResponse(response)
    }

    /// Check if task should terminate
    public func shouldTerminate(
        trajectory: [ReActStep],
        maxCycles: Int
    ) -> Bool {
        if let lastStep = trajectory.last,
           lastStep.action.actionType == .conclude {
            return true
        }

        return trajectory.count >= maxCycles
    }

    /// Update context with step result
    public func updateContext(
        current: String,
        step: ReActStep
    ) -> String {
        """
        \(current)

        ## Step \(step.cycle) Findings
        \(step.actionResult.data)
        """
    }

    // MARK: - Private Methods

    private func buildPrompt(
        task: String,
        context: String,
        trajectory: [ReActStep],
        cycle: Int
    ) -> String {
        let previousSteps = formatTrajectory(trajectory)

        return """
        You are solving a task using ReAct (Reasoning + Acting).

        Task: \(task)

        Available Actions:
        - SEARCH_CODEBASE: Search codebase for relevant code/documentation
        - ANALYZE: Analyze current information without external lookup
        - CONCLUDE: Provide final answer when sufficient information gathered

        Context:
        \(context)

        Previous Steps:
        \(previousSteps)

        Provide your next step in this format:
        THOUGHT: [your reasoning about what to do next]
        ACTION: [SEARCH_CODEBASE|ANALYZE|CONCLUDE]
        QUERY: [specific query or analysis focus]

        Think step-by-step about what information you need next.
        """
    }

    private func formatTrajectory(_ trajectory: [ReActStep]) -> String {
        if trajectory.isEmpty {
            return "None"
        }

        return trajectory.map { step in
            """
            Cycle \(step.cycle):
            Thought: \(step.thought.content)
            Action: \(step.action.actionType) - \(step.action.query)
            Result: \(step.actionResult.summary)
            """
        }.joined(separator: "\n\n")
    }

    private func parseResponse(_ response: String) -> (Thought, ReActAction) {
        let lines = response.components(separatedBy: "\n")
        var thoughtContent = ""
        var actionType: ReActActionType = .analyze
        var query = ""

        for line in lines {
            if line.starts(with: "THOUGHT:") {
                thoughtContent = extractValue(from: line, prefix: "THOUGHT:")
            } else if line.starts(with: "ACTION:") {
                let actionStr = extractValue(from: line, prefix: "ACTION:").uppercased()
                actionType = parseActionType(actionStr)
            } else if line.starts(with: "QUERY:") {
                query = extractValue(from: line, prefix: "QUERY:")
            }
        }

        let thought = Thought(
            id: UUID(),
            content: thoughtContent.isEmpty ? "Continuing analysis" : thoughtContent,
            step: 0,
            type: .observation
        )

        let action = ReActAction(
            actionType: actionType,
            query: query.isEmpty ? thoughtContent : query,
            parameters: [:]
        )

        return (thought, action)
    }

    private func extractValue(from line: String, prefix: String) -> String {
        line.replacingOccurrences(of: prefix, with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private func parseActionType(_ actionStr: String) -> ReActActionType {
        if actionStr.contains("SEARCH") {
            return .searchCodebase
        } else if actionStr.contains("CONCLUDE") {
            return .conclude
        } else {
            return .analyze
        }
    }
}
