import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Default PRD template configuration
/// Extracted for Single Responsibility and file size compliance
struct DefaultPRDTemplate {
    static func create() -> PRDTemplate {
        PRDTemplate(
            name: "Standard PRD",
            description: "Default template with essential sections",
            sections: [
                TemplateSectionConfig(
                    sectionType: .overview,
                    order: 0,
                    isRequired: true,
                    customPrompt: "High-level project description"
                ),
                TemplateSectionConfig(
                    sectionType: .goals,
                    order: 1,
                    isRequired: true,
                    customPrompt: "Project objectives and success criteria"
                ),
                TemplateSectionConfig(
                    sectionType: .requirements,
                    order: 2,
                    isRequired: true,
                    customPrompt: "Functional and non-functional requirements"
                ),
                TemplateSectionConfig(
                    sectionType: .technicalSpecification,
                    order: 3,
                    isRequired: true,
                    customPrompt: "Technical architecture and design"
                )
            ],
            isDefault: true
        )
    }
}
