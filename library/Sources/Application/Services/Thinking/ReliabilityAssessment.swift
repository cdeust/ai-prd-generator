import Foundation

/// Assessment result with score and issues
public struct ReliabilityAssessment: Sendable {
    public let score: Double
    public let issues: [String]

    public init(score: Double, issues: [String]) {
        self.score = score
        self.issues = issues
    }
}
