import Foundation

/// Public professional analysis response
/// Public DTO for analysis results
public struct ProfessionalAnalysisResponse: Sendable {
    public let hasCriticalIssues: Bool
    public let summary: String
    public let conflictCount: Int
    public let challengeCount: Int
    public let complexityScore: Int?

    public init(
        hasCriticalIssues: Bool,
        summary: String,
        conflictCount: Int,
        challengeCount: Int,
        complexityScore: Int? = nil
    ) {
        self.hasCriticalIssues = hasCriticalIssues
        self.summary = summary
        self.conflictCount = conflictCount
        self.challengeCount = challengeCount
        self.complexityScore = complexityScore
    }
}
