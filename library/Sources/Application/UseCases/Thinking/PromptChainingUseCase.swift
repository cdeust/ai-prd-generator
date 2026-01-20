import Foundation
import Domain

/// Prompt Chaining: Break into sub-prompts, chain outputs
/// Single Responsibility: Execute prompt chaining
///
/// **Strategy:** Decompose complex problem into sequence of simpler sub-problems.
/// Output of each step becomes input to next step.
///
/// **Best for:**
/// - Multi-step workflows
/// - Complex tasks that can be decomposed
/// - When intermediate outputs are useful
public struct PromptChainingUseCase: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    public func execute(
        problem: String,
        context: String,
        chain: [ChainStep]
    ) async throws -> PromptChainingResult {
        var intermediateOutputs: [StepOutput] = []
        var accumulatedContext = context

        // Execute each step in the chain
        for (index, step) in chain.enumerated() {
            let prompt = buildStepPrompt(
                step: step,
                problem: problem,
                baseContext: context,
                previousOutputs: intermediateOutputs
            )

            let output = try await aiProvider.generateText(prompt: prompt, temperature: 0.7)

            let stepOutput = StepOutput(
                stepIndex: index,
                stepName: step.name,
                output: output,
                metadata: step.metadata
            )

            intermediateOutputs.append(stepOutput)

            // Update context with latest output
            accumulatedContext += "\n\n[Output from \(step.name)]:\n\(output)"
        }

        // Final output is the last step's output
        let finalOutput = intermediateOutputs.last?.output ?? ""

        return PromptChainingResult(
            solution: finalOutput,
            problem: problem,
            stepsExecuted: intermediateOutputs,
            confidence: estimateConfidence(intermediateOutputs)
        )
    }

    private func buildStepPrompt(
        step: ChainStep,
        problem: String,
        baseContext: String,
        previousOutputs: [StepOutput]
    ) -> String {
        var prompt = """
        <task>
        \(step.instruction)
        </task>

        <original_problem>
        \(problem)
        </original_problem>

        <context>
        \(baseContext)
        </context>

        """

        // Include previous step outputs
        if !previousOutputs.isEmpty {
            prompt += "<previous_steps>\n"
            for output in previousOutputs {
                prompt += """
                Step: \(output.stepName)
                Output: \(output.output)

                """
            }
            prompt += "</previous_steps>\n\n"
        }

        prompt += """
        <instructions>
        \(step.guideline)
        Focus on this specific step only.
        Build upon the previous outputs if available.
        Provide a clear, actionable output for the next step.
        </instructions>
        """

        return prompt
    }

    private func estimateConfidence(_ outputs: [StepOutput]) -> Double {
        // Confidence increases with successful completion of each step
        let baseConfidence = 0.60
        let perStepBonus = 0.05
        let maxConfidence = 0.90

        return min(maxConfidence, baseConfidence + Double(outputs.count) * perStepBonus)
    }
}



