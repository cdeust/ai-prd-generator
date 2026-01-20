import Foundation
import Domain

/// Builds structured Chain-of-Thought prompts with explicit reasoning phases
/// Following Single Responsibility: Only builds structured reasoning prompts
public struct StructuredCoTPromptBuilder: Sendable {

    /// Build structured CoT prompt with XML-based reasoning phases
    public func buildPrompt(
        problem: String,
        context: String,
        constraints: [String]
    ) -> String {
        """
        <task>
        \(problem)
        </task>

        \(buildContextSection(context))
        \(buildConstraintsSection(constraints))

        \(buildThinkingSection())

        \(buildInstructionsSection())
        """
    }

    private func buildThinkingSection() -> String {
        """
        <thinking>
        Think through this problem using structured reasoning. Follow each phase explicitly:

        \(buildUnderstandingPhase())
        \(buildDecompositionPhase())
        \(buildAnalysisPhase())
        \(buildSynthesisPhase())
        \(buildConclusionPhase())
        </thinking>
        """
    }

    private func buildUnderstandingPhase() -> String {
        """
        <phase1_understanding>
        **Understand the Problem:**
        - What is being asked?
        - What are the key inputs and expected outputs?
        - What domain knowledge is relevant?
        </phase1_understanding>
        """
    }

    private func buildDecompositionPhase() -> String {
        """
        <phase2_decomposition>
        **Decompose into Steps:**
        - Break the problem into smaller sub-problems
        - Identify dependencies between steps
        - Note any sequential requirements
        </phase2_decomposition>
        """
    }

    private func buildAnalysisPhase() -> String {
        """
        <phase3_analysis>
        **Analyze Each Component:**
        - For each sub-problem, reason through the solution
        - State any assumptions explicitly (mark with "ASSUMPTION:")
        - Consider edge cases and constraints
        - Evaluate different approaches
        </phase3_analysis>
        """
    }

    private func buildSynthesisPhase() -> String {
        """
        <phase4_synthesis>
        **Synthesize Solution:**
        - Combine findings from all steps
        - Verify logical consistency across reasoning chain
        - Check against all constraints
        </phase4_synthesis>
        """
    }

    private func buildConclusionPhase() -> String {
        """
        <phase5_conclusion>
        **Draw Conclusion:**
        - State the final answer clearly
        - Provide confidence level (high/medium/low)
        - Note any caveats or limitations
        </phase5_conclusion>
        """
    }

    private func buildInstructionsSection() -> String {
        """
        **Important:**
        - Show your reasoning for each phase explicitly
        - Mark assumptions with "ASSUMPTION:"
        - Use "THEREFORE:" before drawing inferences
        - End with "CONCLUSION:" followed by your final answer
        """
    }

    /// Build self-consistency prompt variation
    public func buildSelfConsistencyPrompt(
        problem: String,
        context: String,
        constraints: [String],
        pathNumber: Int
    ) -> String {
        let reasoningStyle = selectReasoningStyle(for: pathNumber)

        return """
        <task>
        \(problem)
        </task>

        \(buildContextSection(context))
        \(buildConstraintsSection(constraints))

        <thinking_approach>
        Use \(reasoningStyle.description) to solve this problem.
        \(reasoningStyle.instructions)
        </thinking_approach>

        <reasoning>
        Think step by step, showing your work for each step.
        Mark key reasoning points:
        - "ASSUMPTION:" for assumptions
        - "INFERENCE:" for logical deductions
        - "THEREFORE:" for conclusions from evidence
        - "CONCLUSION:" for final answer
        </reasoning>
        """
    }

    // MARK: - Private Helpers

    private func buildContextSection(_ context: String) -> String {
        guard !context.isEmpty else { return "" }
        return """

        <context>
        \(context)
        </context>
        """
    }

    private func buildConstraintsSection(_ constraints: [String]) -> String {
        guard !constraints.isEmpty else { return "" }
        let formattedConstraints = constraints.map { "- \($0)" }.joined(separator: "\n")
        return """

        <constraints>
        Consider these requirements:
        \(formattedConstraints)
        </constraints>
        """
    }

    private func selectReasoningStyle(for pathNumber: Int) -> ReasoningStyle {
        switch pathNumber % 3 {
        case 0:
            return .analytical
        case 1:
            return .firstPrinciples
        default:
            return .analogical
        }
    }
}

