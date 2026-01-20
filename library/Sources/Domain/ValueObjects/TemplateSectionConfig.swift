import Foundation

/// Configuration for a section within a PRD template
/// Single Responsibility: Define section configuration in a template
public struct TemplateSectionConfig: Sendable, Codable, Hashable {
    public let sectionType: SectionType
    public let order: Int
    public let isRequired: Bool
    public let customPrompt: String?

    public init(
        sectionType: SectionType,
        order: Int,
        isRequired: Bool = false,
        customPrompt: String? = nil
    ) {
        self.sectionType = sectionType
        self.order = order
        self.isRequired = isRequired
        self.customPrompt = customPrompt
    }

    public func validate() throws {
        guard order >= 0 else {
            throw ValidationError.outOfRange(
                field: "order",
                min: "0",
                max: "unlimited"
            )
        }
    }
}
