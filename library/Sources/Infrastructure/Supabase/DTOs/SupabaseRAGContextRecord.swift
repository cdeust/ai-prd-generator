import Foundation

/// Supabase RAG Context Trace Record
/// Maps to rag_context_traces table (005_intelligence_layer.sql)
public struct SupabaseRAGContextRecord: Codable, Sendable {
    let id: String
    let prdId: String?  // Nullable: set via upsert when PRD is created
    let sectionId: String?
    let codebaseId: String
    let llmInteractionId: String?
    let query: String
    let queryType: String
    let retrievedChunks: [[String: AnyCodable]]?
    let chunkIds: [String]?
    let relevanceScores: [Double]?
    let retrievalMethod: String
    let reasoningForSelection: String
    let impactOnOutput: String?
    let userFeedback: Bool?
    let actualUsefulness: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case prdId = "prd_id"
        case sectionId = "section_id"
        case codebaseId = "codebase_id"
        case llmInteractionId = "llm_interaction_id"
        case query
        case queryType = "query_type"
        case retrievedChunks = "retrieved_chunks"
        case chunkIds = "chunk_ids"
        case relevanceScores = "relevance_scores"
        case retrievalMethod = "retrieval_method"
        case reasoningForSelection = "reasoning_for_selection"
        case impactOnOutput = "impact_on_output"
        case userFeedback = "user_feedback"
        case actualUsefulness = "actual_usefulness"
        case createdAt = "created_at"
    }
}
