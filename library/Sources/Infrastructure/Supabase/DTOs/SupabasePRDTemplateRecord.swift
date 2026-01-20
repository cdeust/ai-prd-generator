import Foundation

/// Supabase database record for PRD templates
/// Single Responsibility: DTO for prd_templates table
public struct SupabasePRDTemplateRecord: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let description: String
    public let sections: [SupabaseTemplateSectionRecord]
    public let isDefault: Bool
    public let createdAt: Date
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case sections
        case isDefault = "is_default"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID,
        name: String,
        description: String,
        sections: [SupabaseTemplateSectionRecord],
        isDefault: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.sections = sections
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
