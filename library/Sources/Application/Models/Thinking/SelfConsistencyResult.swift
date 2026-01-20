import Foundation

/// Result from self-consistency reasoning
public struct SelfConsistencyResult: Sendable {
    public let solution: String
    public let reasoning: String
    public let pathsGenerated: Int
    public let agreementScore: Double
    public let confidence: Double
    public let allPaths: [ReasoningPath]

    public init(
        solution: String,
        reasoning: String,
        pathsGenerated: Int,
        agreementScore: Double,
        confidence: Double,
        allPaths: [ReasoningPath]
    ) {
        self.solution = solution
        self.reasoning = reasoning
        self.pathsGenerated = pathsGenerated
        self.agreementScore = agreementScore
        self.confidence = confidence
        self.allPaths = allPaths
    }
}
