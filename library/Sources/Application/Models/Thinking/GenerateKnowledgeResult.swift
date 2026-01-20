import Foundation

/// Result from generate knowledge reasoning
public struct GenerateKnowledgeResult: Sendable {
    public let solution: String
    public let generatedKnowledge: String
    public let problem: String
    public let confidence: Double

    public init(solution: String, generatedKnowledge: String, problem: String, confidence: Double) {
        self.solution = solution
        self.generatedKnowledge = generatedKnowledge
        self.problem = problem
        self.confidence = confidence
    }
}
