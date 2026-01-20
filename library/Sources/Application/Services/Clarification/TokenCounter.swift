import Foundation

/// Estimates token count for text to manage context window limits
/// Single Responsibility: Token counting and estimation
/// Following naming convention: {Purpose}Service/Counter
public struct TokenCounter: Sendable {

    /// Estimate token count for text
    /// Uses multiple heuristics for better accuracy than simple word counting
    /// - Parameter text: The text to count tokens for
    /// - Returns: Estimated token count
    public func estimateTokens(_ text: String) -> Int {
        // Multiple heuristics for better accuracy:

        // 1. Character-based: ~4 characters per token (GPT standard)
        let charBasedEstimate = text.count / 4

        // 2. Word-based: ~1.3 tokens per word for English
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        let wordBasedEstimate = Int(Double(words.count) * 1.3)

        // 3. Punctuation and special characters add tokens
        let specialChars = text.filter { ".,;:!?()[]{}\"'<>/\\|@#$%^&*-+=~`".contains($0) }
        let punctuationBonus = specialChars.count / 2

        // Use average of character and word estimates, add punctuation
        let averageEstimate = (charBasedEstimate + wordBasedEstimate) / 2
        return averageEstimate + punctuationBonus
    }

    /// Check if text fits within context window with safety margin
    /// - Parameters:
    ///   - text: Text to check
    ///   - contextWindowSize: Maximum context window size
    ///   - safetyMargin: Safety margin to leave (default 200 tokens for response)
    /// - Returns: True if text fits within limit
    public func fitsInContextWindow(
        _ text: String,
        contextWindowSize: Int,
        safetyMargin: Int = 200
    ) -> Bool {
        let estimated = estimateTokens(text)
        return estimated <= (contextWindowSize - safetyMargin)
    }

    /// Calculate remaining token budget
    /// - Parameters:
    ///   - currentText: Current prompt text
    ///   - contextWindowSize: Maximum context window size
    ///   - safetyMargin: Safety margin to leave
    /// - Returns: Remaining tokens available
    public func remainingTokens(
        currentText: String,
        contextWindowSize: Int,
        safetyMargin: Int = 200
    ) -> Int {
        let used = estimateTokens(currentText)
        let available = contextWindowSize - safetyMargin
        return max(0, available - used)
    }

    /// Get budget information for context building
    public struct TokenBudget {
        public let contextWindowSize: Int
        public let safetyMargin: Int
        public let availableForPrompt: Int
        public let currentlyUsed: Int
        public let remaining: Int

        public var utilizationPercentage: Double {
            Double(currentlyUsed) / Double(availableForPrompt) * 100.0
        }

        public var isNearLimit: Bool {
            utilizationPercentage > 80.0
        }

        public var isAtLimit: Bool {
            remaining < 100
        }
    }

    /// Calculate token budget for current context
    /// - Parameters:
    ///   - currentText: Current prompt text
    ///   - contextWindowSize: Maximum context window size
    ///   - safetyMargin: Safety margin for response
    /// - Returns: Token budget information
    public func calculateBudget(
        currentText: String,
        contextWindowSize: Int,
        safetyMargin: Int = 200
    ) -> TokenBudget {
        let used = estimateTokens(currentText)
        let available = contextWindowSize - safetyMargin
        let remaining = max(0, available - used)

        return TokenBudget(
            contextWindowSize: contextWindowSize,
            safetyMargin: safetyMargin,
            availableForPrompt: available,
            currentlyUsed: used,
            remaining: remaining
        )
    }
}
