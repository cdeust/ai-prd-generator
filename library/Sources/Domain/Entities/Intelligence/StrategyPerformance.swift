import Foundation

/// Performance metrics for a strategy execution
/// Captures outcome for learning and optimization
public struct StrategyPerformance: Sendable, Codable {
    public let qualityScore: Double?
    public let executionTimeSeconds: Int?
    public let tokensUsed: Int?
    public let userSatisfaction: Double?
    public let iterationsNeeded: Int?
    public let refinementsApplied: Int?

    public init(
        qualityScore: Double? = nil,
        executionTimeSeconds: Int? = nil,
        tokensUsed: Int? = nil,
        userSatisfaction: Double? = nil,
        iterationsNeeded: Int? = nil,
        refinementsApplied: Int? = nil
    ) {
        self.qualityScore = qualityScore
        self.executionTimeSeconds = executionTimeSeconds
        self.tokensUsed = tokensUsed
        self.userSatisfaction = userSatisfaction
        self.iterationsNeeded = iterationsNeeded
        self.refinementsApplied = refinementsApplied
    }
}
