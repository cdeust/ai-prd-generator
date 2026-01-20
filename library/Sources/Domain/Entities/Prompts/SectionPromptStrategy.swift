import Foundation

/// Strategy for generating section-specific prompts
///
/// Each section type (Overview, Goals, Requirements, etc.) needs different
/// prompt engineering strategies to produce high-quality, professional output.
///
/// Implementations should:
/// - Use specific instructions for the section type
/// - Inject relevant context variables
/// - Apply appropriate constraints
/// - Include domain-specific guidance
public protocol SectionPromptStrategy: Sendable {
    /// The section type this strategy handles
    var sectionType: SectionType { get }

    /// Generates a professional prompt for the given context
    /// - Parameter context: Context data including title, description, requirements
    /// - Returns: A complete PromptTemplate ready for LLM generation
    func generatePrompt(for context: PromptContext) -> PromptTemplate
}
