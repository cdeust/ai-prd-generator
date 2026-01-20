import Foundation

/// Simplified professional analysis result for summaries
/// Following Single Responsibility Principle - simplified result container
public struct ProfessionalAnalysisResult: Sendable {
    public let hasCriticalIssues: Bool
    public let executiveSummary: String
    public let conflictCount: Int
    public let challengeCount: Int
    public let complexityScore: Int?
    public let blockingIssues: [String]

    public init(
        hasCriticalIssues: Bool = false,
        executiveSummary: String = "",
        conflictCount: Int = 0,
        challengeCount: Int = 0,
        complexityScore: Int? = nil,
        blockingIssues: [String] = []
    ) {
        self.hasCriticalIssues = hasCriticalIssues
        self.executiveSummary = executiveSummary
        self.conflictCount = conflictCount
        self.challengeCount = challengeCount
        self.complexityScore = complexityScore
        self.blockingIssues = blockingIssues
    }
}
