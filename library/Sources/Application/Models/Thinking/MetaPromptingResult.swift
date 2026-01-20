import Foundation

/// Result from meta-prompting
public struct MetaPromptingResult: Sendable {
    public let solution: String
    public let problem: String
    public let roleAdopted: Role?
    public let perspectivesUsed: [String]
    public let confidence: Double

    public init(
        solution: String,
        problem: String,
        roleAdopted: Role?,
        perspectivesUsed: [String],
        confidence: Double
    ) {
        self.solution = solution
        self.problem = problem
        self.roleAdopted = roleAdopted
        self.perspectivesUsed = perspectivesUsed
        self.confidence = confidence
    }
}
