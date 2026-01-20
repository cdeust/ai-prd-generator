import Foundation

/// Supabase PRD Section Record
/// Maps to prd_sections table schema (000_complete_schema.sql)
/// Uses optional fields for decoding flexibility with Supabase responses
public struct SupabasePRDSectionRecord: Codable, Sendable {
    let id: String
    let prdDocumentId: String?
    let sectionType: String?
    let title: String?
    let content: String?
    let orderIndex: Int?
    let openapiSpecJson: String?
    let testSuiteJson: String?
    let thinkingStrategy: String?
    let confidence: Double?
    let assumptionsJson: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case prdDocumentId = "prd_document_id"
        case sectionType = "section_type"
        case title
        case content
        case orderIndex = "order_index"
        case openapiSpecJson = "openapi_spec_json"
        case testSuiteJson = "test_suite_json"
        case thinkingStrategy = "thinking_strategy"
        case confidence
        case assumptionsJson = "assumptions_json"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: String,
        prdDocumentId: String,
        sectionType: String,
        title: String,
        content: String,
        orderIndex: Int,
        openapiSpecJson: String? = nil,
        testSuiteJson: String? = nil,
        thinkingStrategy: String? = nil,
        confidence: Double? = nil,
        assumptionsJson: String? = nil,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.prdDocumentId = prdDocumentId
        self.sectionType = sectionType
        self.title = title
        self.content = content
        self.orderIndex = orderIndex
        self.openapiSpecJson = openapiSpecJson
        self.testSuiteJson = testSuiteJson
        self.thinkingStrategy = thinkingStrategy
        self.confidence = confidence
        self.assumptionsJson = assumptionsJson
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
