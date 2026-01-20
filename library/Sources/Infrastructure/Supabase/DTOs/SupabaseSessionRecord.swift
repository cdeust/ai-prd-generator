import Foundation

/// Supabase Session Record
/// Maps to sessions table schema (000_complete_schema.sql)
public struct SupabaseSessionRecord: Codable, Sendable {
    let id: String
    let userId: String
    let prdDocumentId: String?
    let metadataJson: String?
    let startedAt: String
    let endedAt: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case prdDocumentId = "prd_document_id"
        case metadataJson = "metadata_json"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case isActive = "is_active"
    }

    public init(
        id: String,
        userId: String,
        prdDocumentId: String?,
        metadataJson: String?,
        startedAt: String,
        endedAt: String?,
        isActive: Bool
    ) {
        self.id = id
        self.userId = userId
        self.prdDocumentId = prdDocumentId
        self.metadataJson = metadataJson
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.isActive = isActive
    }
}
