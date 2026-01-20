import Foundation
import Domain

/// Executes plan steps with context accumulation
/// Single Responsibility: Execute plan steps and track results
public struct PlanExecutor: Sendable {
    private let aiProvider: AIProviderPort
    private let parser: StructuredCoTParser

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
        self.parser = StructuredCoTParser()
    }

    /// Execute all steps in plan with context accumulation
    public func execute(
        plan: ExecutionPlan,
        initialContext: String
    ) async throws -> [StepResult] {
        var results: [StepResult] = []
        var accumulatedContext = initialContext

        for step in plan.steps {
            let result = try await executeStep(
                step: step,
                context: accumulatedContext
            )

            results.append(result)
            accumulatedContext = updateContext(
                current: accumulatedContext,
                step: step,
                result: result
            )
        }

        return results
    }

    // MARK: - Private Methods

    private func executeStep(
        step: PlanStep,
        context: String
    ) async throws -> StepResult {
        let prompt = buildStepPrompt(step: step, context: context)

        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.5
        )

        let parsed = parser.parse(response)

        return StepResult(
            id: UUID(),
            stepId: step.id,
            stepNumber: step.stepNumber,
            output: parsed.conclusion,
            reasoning: parsed.thoughts.map(\.content).joined(separator: " "),
            confidence: parsed.confidence,
            completedAt: Date()
        )
    }

    private func buildStepPrompt(step: PlanStep, context: String) -> String {
        """
        Execute this step of the plan:

        <step>
        \(step.description)
        </step>

        <requirements>
        \(step.requirements)
        </requirements>

        <expected_output>
        \(step.expectedOutput)
        </expected_output>

        <context>
        \(context)
        </context>

        Provide:
        1. Your reasoning for this step
        2. The output/result
        3. Confidence in this result (0.0-1.0)

        Be specific and thorough.
        """
    }

    private func updateContext(
        current: String,
        step: PlanStep,
        result: StepResult
    ) -> String {
        """
        \(current)

        ## Step \(step.stepNumber) Completed
        Goal: \(step.description)
        Result: \(result.output)
        """
    }
}
