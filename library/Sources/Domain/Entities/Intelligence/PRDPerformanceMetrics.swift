import Foundation

/// Aggregate performance metrics for a PRD
/// Enables learning and optimization over time
public struct PRDPerformanceMetrics: Identifiable, Sendable, Codable {
    public let id: UUID
    public let prdId: UUID
    public let qualityScore: Double?
    public let completenessScore: Double?
    public let clarityScore: Double?
    public let technicalAccuracyScore: Double?
    public let totalGenerationTimeSeconds: Int?
    public let totalTokensUsed: Int?
    public let totalCostUsd: Double?
    public let strategyUsed: String?
    public let strategyEffectiveness: Double?
    public let ragQueriesCount: Int?
    public let ragChunksUsed: Int?
    public let ragRelevanceAvg: Double?
    public let userSatisfactionScore: Double?
    public let userWouldRecommend: Bool?
    public let userFeedbackText: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        prdId: UUID,
        qualityScore: Double? = nil,
        completenessScore: Double? = nil,
        clarityScore: Double? = nil,
        technicalAccuracyScore: Double? = nil,
        totalGenerationTimeSeconds: Int? = nil,
        totalTokensUsed: Int? = nil,
        totalCostUsd: Double? = nil,
        strategyUsed: String? = nil,
        strategyEffectiveness: Double? = nil,
        ragQueriesCount: Int? = nil,
        ragChunksUsed: Int? = nil,
        ragRelevanceAvg: Double? = nil,
        userSatisfactionScore: Double? = nil,
        userWouldRecommend: Bool? = nil,
        userFeedbackText: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.prdId = prdId
        self.qualityScore = qualityScore
        self.completenessScore = completenessScore
        self.clarityScore = clarityScore
        self.technicalAccuracyScore = technicalAccuracyScore
        self.totalGenerationTimeSeconds = totalGenerationTimeSeconds
        self.totalTokensUsed = totalTokensUsed
        self.totalCostUsd = totalCostUsd
        self.strategyUsed = strategyUsed
        self.strategyEffectiveness = strategyEffectiveness
        self.ragQueriesCount = ragQueriesCount
        self.ragChunksUsed = ragChunksUsed
        self.ragRelevanceAvg = ragRelevanceAvg
        self.userSatisfactionScore = userSatisfactionScore
        self.userWouldRecommend = userWouldRecommend
        self.userFeedbackText = userFeedbackText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
