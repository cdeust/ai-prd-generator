import Foundation

/// Professional analysis results for PRD quality (detailed)
/// Following Single Responsibility Principle - comprehensive analysis container
public struct ProfessionalAnalysis: Sendable, Codable {
    public let technicalChallenges: [TechnicalChallenge]
    public let architecturalConflicts: [ArchitecturalConflict]
    public let complexityScore: ComplexityScore
    public let scalingBreakpoints: [ScalingBreakpoint]
    public let dependencyGraph: DependencyGraph?

    public init(
        technicalChallenges: [TechnicalChallenge],
        architecturalConflicts: [ArchitecturalConflict],
        complexityScore: ComplexityScore,
        scalingBreakpoints: [ScalingBreakpoint],
        dependencyGraph: DependencyGraph? = nil
    ) {
        self.technicalChallenges = technicalChallenges
        self.architecturalConflicts = architecturalConflicts
        self.complexityScore = complexityScore
        self.scalingBreakpoints = scalingBreakpoints
        self.dependencyGraph = dependencyGraph
    }

    /// Convert to simplified result
    public func toResult() -> ProfessionalAnalysisResult {
        let hasCritical = complexityScore.overall > 7 ||
            technicalChallenges.contains { $0.severity == .critical }
        let blockingIssues = technicalChallenges
            .filter { $0.severity == .critical }
            .map { $0.title }

        return ProfessionalAnalysisResult(
            hasCriticalIssues: hasCritical,
            executiveSummary: generateSummary(),
            conflictCount: architecturalConflicts.count,
            challengeCount: technicalChallenges.count,
            complexityScore: complexityScore.overall,
            blockingIssues: blockingIssues
        )
    }

    private func generateSummary() -> String {
        buildSummaryText()
    }

    private func buildSummaryText() -> String {
        var summary = "## Professional Analysis Summary\n\n"

        if complexityScore.overall > 7 {
            summary += "⚠️ **High Complexity Detected**\n\n"
        }

        summary += "**Complexity**: \(complexityScore.overall)/10"
        summary += complexityScore.overall > 7 ? " (Needs breakdown)\n" : " (Manageable)\n"
        summary += "**Conflicts**: \(architecturalConflicts.count) detected\n"
        summary += "**Challenges**: \(technicalChallenges.count) predicted\n"

        return summary
    }
}
