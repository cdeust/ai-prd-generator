import Foundation

/// Example for few-shot learning
public struct Example: Sendable, Hashable, Equatable {
    public let input: String
    public let reasoning: String
    public let output: String

    public init(input: String, reasoning: String, output: String) {
        self.input = input
        self.reasoning = reasoning
        self.output = output
    }
}
