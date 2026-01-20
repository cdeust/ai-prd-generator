import Foundation

/// Supabase record for template section configuration
/// Single Responsibility: DTO for template section data
public struct SupabaseTemplateSectionRecord: Codable, Sendable {
    public let sectionType: String
    public let order: Int
    public let isRequired: Bool
    public let customPrompt: String?

    enum CodingKeys: String, CodingKey {
        case sectionType = "section_type"
        case order
        case isRequired = "is_required"
        case customPrompt = "custom_prompt"
    }

    public init(
        sectionType: String,
        order: Int,
        isRequired: Bool,
        customPrompt: String?
    ) {
        self.sectionType = sectionType
        self.order = order
        self.isRequired = isRequired
        self.customPrompt = customPrompt
    }
}
