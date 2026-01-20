import Foundation

/// Statistical summary of verification outcomes
public struct VerificationStatistics: Sendable, Codable {
    public let verificationType: VerificationType
    public let totalVerifications: Int
    public let averageScore: Double
    public let averageConfidence: Double
    public let verificationRate: Double // % that passed verification
    public let averageDurationMs: Int?

    public init(
        verificationType: VerificationType,
        totalVerifications: Int,
        averageScore: Double,
        averageConfidence: Double,
        verificationRate: Double,
        averageDurationMs: Int? = nil
    ) {
        self.verificationType = verificationType
        self.totalVerifications = totalVerifications
        self.averageScore = averageScore
        self.averageConfidence = averageConfidence
        self.verificationRate = verificationRate
        self.averageDurationMs = averageDurationMs
    }

    /// Recommended threshold based on historical data
    /// Uses mean - 1 standard deviation for conservative threshold
    public var recommendedThreshold: Double {
        // Conservative: Accept if above historical average
        max(0.5, averageScore * 0.9) // 90% of historical average
    }
}
