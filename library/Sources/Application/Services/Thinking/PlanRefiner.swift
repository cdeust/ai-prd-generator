import Foundation
import Domain

/// Refines Plan-and-Solve results with feedback-driven re-planning
///
/// **3R's Justification:**
/// - **Reliability**: Testable refinement logic in isolation
/// - **Readability**: Clear separation of refinement concerns
/// - **Reusability**: Any PlanAndSolve variant can use this
///
/// Single Responsibility: Refine execution plans based on verification feedback
public struct PlanRefiner: Sendable {
    private let aiProvider: AIProviderPort
    private let planParser: PlanParser
    private let planExecutor: PlanExecutor
    private let planVerifier: PlanVerifier

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
        self.planParser = PlanParser()
        self.planExecutor = PlanExecutor(aiProvider: aiProvider)
        self.planVerifier = PlanVerifier(aiProvider: aiProvider)
    }

    /// Refine PlanAndSolveResult by re-planning based on verification feedback
    public func refine(
        previousResult: PlanAndSolveResult,
        problem: String,
        context: String,
        constraints: [String]
    ) async throws -> PlanAndSolveResult {
        let feedback = extractVerificationFeedback(previousResult.verification)

        let revisedPlan = try await createRevisedPlan(
            problem: problem,
            context: context,
            constraints: constraints,
            previousPlan: previousResult.plan,
            feedback: feedback
        )

        let executionResults = try await planExecutor.execute(
            plan: revisedPlan,
            initialContext: context
        )

        let verification = try await planVerifier.verify(
            problem: problem,
            plan: revisedPlan,
            results: executionResults,
            context: context
        )

        return buildResult(
            problem: problem,
            plan: revisedPlan,
            executionResults: executionResults,
            verification: verification
        )
    }

    // MARK: - Private Methods

    private func extractVerificationFeedback(
        _ verification: PlanVerification
    ) -> String {
        var feedback = ""

        if !verification.identifiedGaps.isEmpty {
            feedback += "Gaps identified:\n"
            feedback += verification.identifiedGaps.map { "- \($0)" }.joined(separator: "\n")
            feedback += "\n\n"
        }

        if !verification.recommendations.isEmpty {
            feedback += "Recommendations:\n"
            feedback += verification.recommendations.map { "- \($0)" }
                .joined(separator: "\n")
        }

        return feedback
    }

    private func createRevisedPlan(
        problem: String,
        context: String,
        constraints: [String],
        previousPlan: ExecutionPlan,
        feedback: String
    ) async throws -> ExecutionPlan {
        let prompt = buildRevisedPlanningPrompt(
            problem: problem,
            context: context,
            constraints: constraints,
            previousPlan: previousPlan,
            feedback: feedback
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.3
        )

        return planParser.parse(response: response, problem: problem)
    }

    private func buildRevisedPlanningPrompt(
        problem: String,
        context: String,
        constraints: [String],
        previousPlan: ExecutionPlan,
        feedback: String
    ) -> String {
        """
        Revise the plan to solve this problem based on feedback:

        <problem>
        \(problem)
        </problem>

        <context>
        \(context)
        </context>

        <constraints>
        \(constraints.map { "- \($0)" }.joined(separator: "\n"))
        </constraints>

        <previous_plan>
        \(previousPlan.steps.enumerated().map { "Step \($0.offset + 1): \($0.element.description)" }
            .joined(separator: "\n"))
        </previous_plan>

        <feedback>
        \(feedback)
        </feedback>

        Create an improved step-by-step plan addressing the feedback:

        1. Address identified gaps
        2. Incorporate recommendations
        3. Maintain logical ordering
        4. Clarify dependencies

        Format:
        STEP_N: [description]
        REQUIRES: [what's needed for this step]
        PRODUCES: [what this step delivers]
        CHALLENGES: [potential issues]
        """
    }

    private func buildResult(
        problem: String,
        plan: ExecutionPlan,
        executionResults: [StepResult],
        verification: PlanVerification
    ) -> PlanAndSolveResult {
        let finalOutput = executionResults.last?.output ?? "No conclusion"

        let totalConfidence = executionResults.map(\.confidence).reduce(0.0, +)
        let averageConfidence = totalConfidence / Double(executionResults.count)

        return PlanAndSolveResult(
            problem: problem,
            plan: plan,
            executionResults: executionResults,
            verification: verification,
            finalOutput: finalOutput,
            averageConfidence: averageConfidence
        )
    }
}
