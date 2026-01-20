import Foundation
import Domain

/// Mapper between PRDTemplate domain entity and Supabase DTOs
/// Single Responsibility: Map template domain<->database representations
public enum SupabasePRDTemplateMapper {
    public static func toDomain(
        _ record: SupabasePRDTemplateRecord
    ) throws -> PRDTemplate {
        let sections = try record.sections.map(toDomainSection)

        return PRDTemplate(
            id: record.id,
            name: record.name,
            description: record.description,
            sections: sections,
            isDefault: record.isDefault,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    public static func toRecord(_ template: PRDTemplate) -> SupabasePRDTemplateRecord {
        let sections = template.sections.map(toRecordSection)

        return SupabasePRDTemplateRecord(
            id: template.id,
            name: template.name,
            description: template.description,
            sections: sections,
            isDefault: template.isDefault,
            createdAt: template.createdAt,
            updatedAt: template.updatedAt
        )
    }

    private static func toDomainSection(
        _ record: SupabaseTemplateSectionRecord
    ) throws -> TemplateSectionConfig {
        guard let sectionType = SectionType(rawValue: record.sectionType) else {
            throw SupabaseTemplateError.invalidSectionType(record.sectionType)
        }

        return TemplateSectionConfig(
            sectionType: sectionType,
            order: record.order,
            isRequired: record.isRequired,
            customPrompt: record.customPrompt
        )
    }

    private static func toRecordSection(
        _ config: TemplateSectionConfig
    ) -> SupabaseTemplateSectionRecord {
        SupabaseTemplateSectionRecord(
            sectionType: config.sectionType.rawValue,
            order: config.order,
            isRequired: config.isRequired,
            customPrompt: config.customPrompt
        )
    }
}
