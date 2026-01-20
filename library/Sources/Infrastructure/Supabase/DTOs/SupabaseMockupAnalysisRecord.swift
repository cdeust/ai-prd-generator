import Foundation

/// Supabase Mockup Analysis Trace Record
/// Maps to mockup_analysis_traces table (005_intelligence_layer.sql)
public struct SupabaseMockupAnalysisRecord: Codable, Sendable {
    let id: String
    let mockupId: String
    let prdId: String?  // Nullable: set later when mockup is associated with PRD
    let llmInteractionId: String?
    let analysisPrompt: String
    let llmResponse: String
    let detectedPatterns: [[String: AnyCodable]]?
    let uiComponents: [String]?
    let colorScheme: [String: String]?
    let layoutType: String?
    let uncertainties: [String]?
    let clarificationQuestions: [String]?
    let influencedSections: [String]?
    let confidenceScore: Double?
    let visionModel: String
    let visionProvider: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case mockupId = "mockup_id"
        case prdId = "prd_id"
        case llmInteractionId = "llm_interaction_id"
        case analysisPrompt = "analysis_prompt"
        case llmResponse = "llm_response"
        case detectedPatterns = "detected_patterns"
        case uiComponents = "ui_components"
        case colorScheme = "color_scheme"
        case layoutType = "layout_type"
        case uncertainties
        case clarificationQuestions = "clarification_questions"
        case influencedSections = "influenced_sections"
        case confidenceScore = "confidence_score"
        case visionModel = "vision_model"
        case visionProvider = "vision_provider"
        case createdAt = "created_at"
    }
}
