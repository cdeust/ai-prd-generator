import Foundation

/// Supabase Clarification Trace Record
/// Maps to clarification_traces table (005_intelligence_layer.sql)
public struct SupabaseClarificationRecord: Codable, Sendable {
    let id: String
    let prdId: String?  // Nullable: clarifications happen before PRD exists, updated via upsert
    let questionId: String
    let questionText: String
    let questionCategory: String?
    let reasoningForAsking: String
    let gapAddressed: String
    let userAnswer: String?
    let answerTimestamp: Date?
    let impactOnPrd: String?
    let influencedSections: [String]?
    let wasHelpful: Bool?
    let improvedQuality: Bool?
    let shouldAskAgainForSimilar: Bool?
    let coherenceScore: Double?     // Pre-ask coherence score (0.0-1.0)
    let valueAddScore: Double?      // Pre-ask value-add score (0.0-1.0)
    let wasAskedToUser: Bool?       // Whether question passed threshold and was asked
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case prdId = "prd_id"
        case questionId = "question_id"
        case questionText = "question_text"
        case questionCategory = "question_category"
        case reasoningForAsking = "reasoning_for_asking"
        case gapAddressed = "gap_addressed"
        case userAnswer = "user_answer"
        case answerTimestamp = "answer_timestamp"
        case impactOnPrd = "impact_on_prd"
        case influencedSections = "influenced_sections"
        case wasHelpful = "was_helpful"
        case improvedQuality = "improved_quality"
        case shouldAskAgainForSimilar = "should_ask_again_for_similar"
        case coherenceScore = "coherence_score"
        case valueAddScore = "value_add_score"
        case wasAskedToUser = "was_asked_to_user"
        case createdAt = "created_at"
    }
}
