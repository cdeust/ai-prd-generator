import Foundation

/// Supabase Strategy Decision Record
/// Maps to thinking_strategy_decisions table (005_intelligence_layer.sql)
public struct SupabaseStrategyDecisionRecord: Codable, Sendable {
    let id: String
    let prdId: String?  // Nullable: set via upsert when PRD is created
    let sectionId: String?
    let strategyChosen: String
    let reasoning: String
    let confidenceScore: Double?
    let inputCharacteristics: [String: AnyCodable]?
    let alternativesConsidered: [String]?
    let actualPerformance: [String: AnyCodable]?
    let wasEffective: Bool?
    let lessonsLearned: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case prdId = "prd_id"
        case sectionId = "section_id"
        case strategyChosen = "strategy_chosen"
        case reasoning
        case confidenceScore = "confidence_score"
        case inputCharacteristics = "input_characteristics"
        case alternativesConsidered = "alternatives_considered"
        case actualPerformance = "actual_performance"
        case wasEffective = "was_effective"
        case lessonsLearned = "lessons_learned"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
