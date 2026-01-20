import Foundation

/// Result from multimodal reasoning
public struct MultimodalCoTResult: Sendable {
    public let solution: String
    public let reasoning: String
    public let visualContexts: [VisualContext]
    public let problem: String
    public let confidence: Double

    public init(
        solution: String,
        reasoning: String,
        visualContexts: [VisualContext],
        problem: String,
        confidence: Double
    ) {
        self.solution = solution
        self.reasoning = reasoning
        self.visualContexts = visualContexts
        self.problem = problem
        self.confidence = confidence
    }
}
