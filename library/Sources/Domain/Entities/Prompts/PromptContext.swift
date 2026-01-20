import Foundation

/// Context data for generating section-specific prompts
///
/// Contains all information needed to generate high-quality,
/// context-aware prompts for PRD sections.
public struct PromptContext: Sendable {
    /// Project title
    public let title: String

    /// Project description
    public let description: String

    /// User-provided requirements
    public let requirements: [String]

    /// Target section type
    public let sectionType: SectionType

    /// Optional: Previously generated sections (for context)
    public let previousSections: [SectionType: String]

    /// Optional: Domain-specific keywords
    public let domainKeywords: [String]

    /// Optional: Target audience hints
    public let targetAudience: String?

    /// Optional: Technical complexity level
    public let complexityLevel: ComplexityLevel

    public init(
        title: String,
        description: String,
        requirements: [String] = [],
        sectionType: SectionType,
        previousSections: [SectionType: String] = [:],
        domainKeywords: [String] = [],
        targetAudience: String? = nil,
        complexityLevel: ComplexityLevel = .medium
    ) {
        self.title = title
        self.description = description
        self.requirements = requirements
        self.sectionType = sectionType
        self.previousSections = previousSections
        self.domainKeywords = domainKeywords
        self.targetAudience = targetAudience
        self.complexityLevel = complexityLevel
    }
}
