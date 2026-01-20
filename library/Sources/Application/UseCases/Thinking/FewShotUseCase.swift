import Foundation
import Domain

/// Few-shot prompting: Problem solving with example demonstrations
/// Single Responsibility: Execute few-shot reasoning
///
/// **Strategy:** Provide examples of similar problems and their solutions
/// to guide the model toward the desired output format and reasoning style.
///
/// **Best for:**
/// - Tasks requiring specific output format
/// - Domain-specific problems
/// - When model needs guidance on reasoning style
public struct FewShotUseCase: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    public func execute(
        problem: String,
        context: String,
        examples: [Example],
        taskInstructions: String
    ) async throws -> FewShotResult {
        let prompt = buildFewShotPrompt(
            problem: problem,
            context: context,
            examples: examples,
            instructions: taskInstructions
        )

        let response = try await aiProvider.generateText(prompt: prompt, temperature: 0.7)

        return FewShotResult(
            solution: response,
            problem: problem,
            examplesUsed: examples.count,
            confidence: estimateConfidence(response, exampleCount: examples.count)
        )
    }

    private func buildFewShotPrompt(
        problem: String,
        context: String,
        examples: [Example],
        instructions: String
    ) -> String {
        var prompt = """
        <task>
        \(instructions)
        </task>

        <context>
        \(context)
        </context>

        <examples>
        Here are examples of how to approach similar problems:

        """

        // Add each example
        for (index, example) in examples.enumerated() {
            prompt += """

            Example \(index + 1):
            Input: \(example.input)
            Reasoning: \(example.reasoning)
            Output: \(example.output)

            """
        }

        prompt += """
        </examples>

        <problem>
        Now solve this problem following the same format and reasoning style:
        \(problem)
        </problem>

        <instructions>
        Follow the pattern shown in the examples above.
        Provide your reasoning step-by-step.
        Format your output consistently with the examples.
        </instructions>
        """

        return prompt
    }

    private func estimateConfidence(_ response: String, exampleCount: Int) -> Double {
        // More examples generally lead to better performance
        let baseConfidence = min(0.85, 0.65 + Double(exampleCount) * 0.05)

        let hasStructuredFormat = response.contains("Reasoning:") || response.contains("Output:")
        let followsPattern = hasStructuredFormat && response.count > 100

        if followsPattern {
            return min(0.90, baseConfidence + 0.10)
        } else {
            return baseConfidence
        }
    }
}
