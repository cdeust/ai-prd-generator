import Foundation
import Domain

/// Allocates token budget between prompt and output
/// Based on provider context window size
///
/// Budget allocation strategy:
/// - Prompt: 70% of context window (input context)
/// - Output: 30% of context window (generated content)
/// - Safety buffer: 5% reserved for overhead
///
/// **Example (Apple Intelligence 8K window):**
/// - Total: 8,192 tokens
/// - Safety buffer: 410 tokens (5%)
/// - Available: 7,782 tokens
/// - Prompt budget: 5,447 tokens (70%)
/// - Output budget: 2,335 tokens (30%)
public struct ContextBudgetAllocator: Sendable {
    private let tokenizer: TokenizerPort

    public init(tokenizer: TokenizerPort) {
        self.tokenizer = tokenizer
    }

    /// Allocate token budget based on provider context window
    public func allocateBudget(
        for provider: AIProviderPort
    ) -> PromptBudget {
        let contextWindow = provider.contextWindowSize
        let safetyBuffer = Int(Double(contextWindow) * 0.05)
        let availableTokens = contextWindow - safetyBuffer

        let promptBudget = Int(Double(availableTokens) * 0.70)
        let outputBudget = Int(Double(availableTokens) * 0.30)

        return PromptBudget(
            contextWindowSize: contextWindow,
            safetyBuffer: safetyBuffer,
            promptBudget: promptBudget,
            outputBudget: outputBudget,
            providerName: provider.providerName
        )
    }

    /// Check if prompt fits within budget
    public func fitsWithinBudget(
        prompt: String,
        budget: PromptBudget
    ) async throws -> Bool {
        let tokenCount = try await tokenizer.countTokens(in: prompt)
        return tokenCount <= budget.promptBudget
    }

    /// Get token count for text
    public func countTokens(
        in text: String
    ) async throws -> Int {
        return try await tokenizer.countTokens(in: text)
    }
}
