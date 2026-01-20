import Foundation

/// Metrics for a specific refinement attempt number
public struct RefinementAttemptMetrics: Sendable, Codable {
    public let attemptNumber: Int
    public let totalAttempts: Int
    public let averageScore: Double
    public let successRate: Double

    public init(
        attemptNumber: Int,
        totalAttempts: Int,
        averageScore: Double,
        successRate: Double
    ) {
        self.attemptNumber = attemptNumber
        self.totalAttempts = totalAttempts
        self.averageScore = averageScore
        self.successRate = successRate
    }
}
