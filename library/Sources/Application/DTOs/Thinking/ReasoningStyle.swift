import Foundation

/// Reasoning approach style
/// Different approaches for problem-solving
public enum ReasoningStyle: Sendable {
    case analytical
    case firstPrinciples
    case analogical

    var description: String {
        switch self {
        case .analytical: return "analytical decomposition"
        case .firstPrinciples: return "first principles reasoning"
        case .analogical: return "analogical reasoning"
        }
    }

    var instructions: String {
        switch self {
        case .analytical:
            return "Break down into components, analyze each part systematically."
        case .firstPrinciples:
            return "Start from fundamental truths, build up the solution from basic principles."
        case .analogical:
            return "Find similar problems or patterns, apply learnings to this case."
        }
    }
}
