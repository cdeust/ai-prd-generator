import Foundation
import Domain

/// Zero-shot prompting: Direct problem solving without examples
/// Single Responsibility: Execute zero-shot reasoning
///
/// **Strategy:** Ask the LLM to solve the problem directly with clear instructions
/// but no examples. Relies on model's pre-trained knowledge.
///
/// **Best for:**
/// - Well-defined problems
/// - Problems similar to training data
/// - When examples are unavailable
public struct ZeroShotUseCase: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    public func execute(
        problem: String,
        context: String,
        taskInstructions: String
    ) async throws -> ZeroShotResult {
        let prompt = buildZeroShotPrompt(
            problem: problem,
            context: context,
            instructions: taskInstructions
        )

        let response = try await aiProvider.generateText(prompt: prompt, temperature: 0.7)

        return ZeroShotResult(
            solution: response,
            problem: problem,
            confidence: estimateConfidence(response)
        )
    }

    private func buildZeroShotPrompt(
        problem: String,
        context: String,
        instructions: String
    ) -> String {
        """
        <task>
        \(instructions)
        </task>

        <context>
        \(context)
        </context>

        <problem>
        \(problem)
        </problem>

        <instructions>
        Solve the problem directly based on your knowledge.
        Provide a clear, structured solution.
        Explain your reasoning briefly.
        </instructions>
        """
    }

    private func estimateConfidence(_ response: String) -> Double {
        // Heuristic confidence based on response characteristics
        let hasHedging = response.lowercased().contains("might") ||
                        response.lowercased().contains("possibly") ||
                        response.lowercased().contains("maybe")

        let hasConfidentLanguage = response.lowercased().contains("clearly") ||
                                  response.lowercased().contains("definitely") ||
                                  response.lowercased().contains("should")

        if hasConfidentLanguage && !hasHedging {
            return 0.85
        } else if !hasHedging {
            return 0.75
        } else {
            return 0.60
        }
    }
}

