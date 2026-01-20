import Foundation

/// Reasoning result from thinking process
/// Domain value object containing reasoning outcomes
public struct ReasoningResult: Sendable {
    public let decision: String
    public let rationale: [String]
    public let alternatives: [String]

    public init(
        decision: String,
        rationale: [String],
        alternatives: [String] = []
    ) {
        self.decision = decision
        self.rationale = rationale
        self.alternatives = alternatives
    }
}
