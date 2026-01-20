import Foundation

/// Judge performance metrics for reliability analysis
public struct JudgePerformanceMetrics: Sendable, Codable {
    public let judgeProvider: String
    public let judgeModel: String
    public let totalEvaluations: Int
    public let averageScore: Double
    public let averageConfidence: Double
    public let averageDeviation: Double // From consensus
    public let reliabilityScore: Double // 0-1, higher = more reliable

    public init(
        judgeProvider: String,
        judgeModel: String,
        totalEvaluations: Int,
        averageScore: Double,
        averageConfidence: Double,
        averageDeviation: Double,
        reliabilityScore: Double
    ) {
        self.judgeProvider = judgeProvider
        self.judgeModel = judgeModel
        self.totalEvaluations = totalEvaluations
        self.averageScore = averageScore
        self.averageConfidence = averageConfidence
        self.averageDeviation = averageDeviation
        self.reliabilityScore = reliabilityScore
    }

    /// Whether this judge is considered reliable
    /// Reliable = low deviation from consensus + high consistency
    public var isReliable: Bool {
        reliabilityScore > 0.7 && totalEvaluations >= 10
    }
}
