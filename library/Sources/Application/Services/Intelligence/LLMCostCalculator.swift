import Foundation

/// Calculator for LLM token costs
/// Single Responsibility: Cost estimation for different LLM models
public struct LLMCostCalculator: Sendable {

    public init() {}

    /// Calculate total tokens from prompt and response
    public func calculateTotal(prompt: Int?, response: Int?) -> Int? {
        guard let p = prompt, let r = response else { return nil }
        return p + r
    }

    /// Calculate estimated cost in USD based on model and token count
    public func calculateCost(model: String, tokens: Int?) -> Double? {
        guard let tokens = tokens else { return nil }

        // Approximate costs per 1M tokens (input + output average)
        let costPer1M: Double
        switch model.lowercased() {
        case let m where m.contains("claude-3-opus"):
            costPer1M = 45.0  // $15 input + $75 output average
        case let m where m.contains("claude-3-5-sonnet"):
            costPer1M = 9.0   // $3 input + $15 output average
        case let m where m.contains("claude-3-haiku"):
            costPer1M = 0.5   // $0.25 input + $1.25 output average
        case let m where m.contains("gpt-4"):
            costPer1M = 45.0
        case let m where m.contains("gpt-3.5"):
            costPer1M = 1.0
        default:
            costPer1M = 5.0   // Default estimate
        }

        return (Double(tokens) / 1_000_000.0) * costPer1M
    }
}
