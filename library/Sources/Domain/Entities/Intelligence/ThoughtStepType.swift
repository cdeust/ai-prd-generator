import Foundation

/// Type of thought step in reasoning chain
public enum ThoughtStepType: String, Sendable, Codable, CaseIterable {
    case observation = "observation"
    case reasoning = "reasoning"
    case action = "action"
    case reflection = "reflection"
    case hypothesis = "hypothesis"
    case conclusion = "conclusion"
}
