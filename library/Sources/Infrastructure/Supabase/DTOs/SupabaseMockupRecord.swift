import Foundation

/// Supabase Mockup Record
/// Maps to mockups table schema (000_complete_schema.sql)
public struct SupabaseMockupRecord: Codable, Sendable {
    let id: String
    let prdDocumentId: String?
    let name: String
    let description: String?
    let mockupType: String
    let source: String
    let fileUrl: String
    let fileSize: Int?
    let width: Int?
    let height: Int?
    let analysisResultJson: String?
    let orderIndex: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case prdDocumentId = "prd_document_id"
        case name
        case description
        case mockupType = "mockup_type"
        case source
        case fileUrl = "file_url"
        case fileSize = "file_size"
        case width
        case height
        case analysisResultJson = "analysis_result_json"
        case orderIndex = "order_index"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: String,
        prdDocumentId: String?,
        name: String,
        description: String?,
        mockupType: String,
        source: String,
        fileUrl: String,
        fileSize: Int?,
        width: Int?,
        height: Int?,
        analysisResultJson: String?,
        orderIndex: Int,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.prdDocumentId = prdDocumentId
        self.name = name
        self.description = description
        self.mockupType = mockupType
        self.source = source
        self.fileUrl = fileUrl
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.analysisResultJson = analysisResultJson
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Custom encode to ensure all keys are present (PostgREST requires consistent keys in batch inserts)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(prdDocumentId, forKey: .prdDocumentId)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(mockupType, forKey: .mockupType)
        try container.encode(source, forKey: .source)
        try container.encode(fileUrl, forKey: .fileUrl)
        try container.encode(fileSize, forKey: .fileSize)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(analysisResultJson, forKey: .analysisResultJson)
        try container.encode(orderIndex, forKey: .orderIndex)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
