import Foundation

/// Supabase PRD Performance Metrics Record
/// Maps to prd_performance_metrics table (005_intelligence_layer.sql)
public struct SupabasePerformanceMetricsRecord: Codable, Sendable {
    let id: String
    let prdId: String
    let qualityScore: Double?
    let completenessScore: Double?
    let clarityScore: Double?
    let technicalAccuracyScore: Double?
    let totalGenerationTimeS: Int?
    let totalTokensUsed: Int?
    let totalCostUsd: Double?
    let strategyUsed: String?
    let strategyEffectiveness: Double?
    let ragQueriesCount: Int?
    let ragChunksUsed: Int?
    let ragRelevanceAvg: Double?
    let userSatisfactionScore: Double?
    let userWouldRecommend: Bool?
    let userFeedbackText: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case prdId = "prd_id"
        case qualityScore = "quality_score"
        case completenessScore = "completeness_score"
        case clarityScore = "clarity_score"
        case technicalAccuracyScore = "technical_accuracy_score"
        case totalGenerationTimeS = "total_generation_time_s"
        case totalTokensUsed = "total_tokens_used"
        case totalCostUsd = "total_cost_usd"
        case strategyUsed = "strategy_used"
        case strategyEffectiveness = "strategy_effectiveness"
        case ragQueriesCount = "rag_queries_count"
        case ragChunksUsed = "rag_chunks_used"
        case ragRelevanceAvg = "rag_relevance_avg"
        case userSatisfactionScore = "user_satisfaction_score"
        case userWouldRecommend = "user_would_recommend"
        case userFeedbackText = "user_feedback_text"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
