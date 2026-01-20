import Foundation

/// Supabase PRD Document Record
/// Maps to prd_documents table schema (000_complete_schema.sql)
/// Uses String for UUIDs to ensure lowercase format matches PostgreSQL
public struct SupabasePRDDocumentRecord: Codable, Sendable {
    let id: String
    let userId: String?
    let codebaseId: String?
    let title: String
    let description: String?
    let version: String?
    let status: String?
    let metadataJson: PRDMetadataJSON?
    let thinkingChainJson: [[String: String]]?
    let professionalAnalysisJson: [String: String]?
    let thinkingMode: String?
    let privacyLevel: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case codebaseId = "codebase_id"
        case title
        case description
        case version
        case status
        case metadataJson = "metadata_json"
        case thinkingChainJson = "thinking_chain_json"
        case professionalAnalysisJson = "professional_analysis_json"
        case thinkingMode = "thinking_mode"
        case privacyLevel = "privacy_level"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
