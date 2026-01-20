import Foundation

/// Supabase LLM Interaction Trace Record
/// Maps to llm_interaction_traces table (005_intelligence_layer.sql)
public struct SupabaseLLMInteractionRecord: Codable, Sendable {
    let id: String
    let prdId: String?  // Nullable: LLM calls happen before PRD exists, updated via upsert
    let sectionId: String?
    let timestamp: Date?
    let purpose: String
    let contextType: String?
    let promptTemplate: String
    let actualPrompt: String
    let systemInstructions: String?
    let llmModel: String
    let provider: String
    let parameters: [String: AnyCodable]?
    let response: String
    let responseMetadata: [String: String]?
    let tokensPrompt: Int?
    let tokensResponse: Int?
    let tokensTotal: Int?
    let latencyMs: Int?
    let costUsd: Double?
    let thinkingStrategy: String?
    let thinkingDepth: Int?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case prdId = "prd_id"
        case sectionId = "section_id"
        case timestamp
        case purpose
        case contextType = "context_type"
        case promptTemplate = "prompt_template"
        case actualPrompt = "actual_prompt"
        case systemInstructions = "system_instructions"
        case llmModel = "llm_model"
        case provider
        case parameters
        case response
        case responseMetadata = "response_metadata"
        case tokensPrompt = "tokens_prompt"
        case tokensResponse = "tokens_response"
        case tokensTotal = "tokens_total"
        case latencyMs = "latency_ms"
        case costUsd = "cost_usd"
        case thinkingStrategy = "thinking_strategy"
        case thinkingDepth = "thinking_depth"
        case createdAt = "created_at"
    }
}
