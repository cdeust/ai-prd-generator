import Foundation

/// A step in the prompt chain
public struct ChainStep: Sendable {
    public let name: String
    public let instruction: String
    public let guideline: String
    public let metadata: [String: String]

    public init(
        name: String,
        instruction: String,
        guideline: String = "Complete this step thoroughly.",
        metadata: [String: String] = [:]
    ) {
        self.name = name
        self.instruction = instruction
        self.guideline = guideline
        self.metadata = metadata
    }
}
