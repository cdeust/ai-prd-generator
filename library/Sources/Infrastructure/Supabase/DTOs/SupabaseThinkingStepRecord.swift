import Foundation

/// Supabase Thinking Chain Step Record
/// Maps to thinking_chain_steps table (005_intelligence_layer.sql)
public struct SupabaseThinkingStepRecord: Codable, Sendable {
    let id: String
    let prdId: String?  // Nullable: set via upsert when PRD is created
    let sectionId: String?
    let llmInteractionId: String?
    let stepNumber: Int
    let thoughtType: String
    let content: String
    let evidenceUsed: [[String: AnyCodable]]?
    let confidence: Double?
    let tokensUsed: Int?
    let executionTimeMs: Int?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case prdId = "prd_id"
        case sectionId = "section_id"
        case llmInteractionId = "llm_interaction_id"
        case stepNumber = "step_number"
        case thoughtType = "thought_type"
        case content
        case evidenceUsed = "evidence_used"
        case confidence
        case tokensUsed = "tokens_used"
        case executionTimeMs = "execution_time_ms"
        case createdAt = "created_at"
    }
}
