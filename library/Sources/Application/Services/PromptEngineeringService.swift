import Foundation
import Domain

/// Service for generating sophisticated, section-specific prompts
///
/// Transforms generic PRD generation into professional, high-quality output
/// by using specialized prompt templates for each section type.
///
/// Responsibilities:
/// - Map section types to appropriate prompt strategies
/// - Generate context-aware prompts with variable injection
/// - Apply constraints and quality guidelines per section
///
/// Clean Architecture: Application Service
/// - Depends on Domain (SectionPromptStrategy protocol)
/// - Used by GeneratePRDUseCase
/// - Infrastructure provides concrete implementations
public actor PromptEngineeringService {
    private let strategies: [SectionType: SectionPromptStrategy]

    /// Initialize with prompt strategies for each section type
    /// - Parameter strategies: Dictionary mapping section types to their strategies
    public init(strategies: [SectionType: SectionPromptStrategy]) {
        self.strategies = strategies
    }

    /// Generate a professional prompt for a specific section
    /// - Parameters:
    ///   - sectionType: The type of section to generate
    ///   - context: Context data including title, description, requirements
    /// - Returns: A complete prompt string ready for LLM generation
    /// - Throws: PromptEngineeringError if strategy not found
    public func generateSectionPrompt(
        for sectionType: SectionType,
        context: PromptContext
    ) throws -> String {
        guard let strategy = strategies[sectionType] else {
            throw PromptEngineeringError.strategyNotFound(sectionType: sectionType)
        }

        let template = strategy.generatePrompt(for: context)
        return template.generateFull()
    }

    /// Generate a simple prompt for a section without sophisticated engineering
    /// Fallback for sections without specialized strategies
    /// - Parameters:
    ///   - sectionType: The type of section to generate
    ///   - context: Context data
    /// - Returns: A basic prompt string
    public func generateFallbackPrompt(
        for sectionType: SectionType,
        context: PromptContext
    ) -> String {
        """
        Generate a comprehensive \(sectionType.rawValue) section for the following project:

        **Project Title:** \(context.title)
        **Description:** \(context.description)

        \(formatRequirements(context.requirements))

        Write in a clear, professional tone with specific details.
        Length: 200-400 words.
        """
    }

    private func formatRequirements(_ requirements: [String]) -> String {
        guard !requirements.isEmpty else {
            return ""
        }

        let formatted = requirements
            .enumerated()
            .map { "\($0 + 1). \($1)" }
            .joined(separator: "\n")

        return """
        **User Requirements:**
        \(formatted)
        """
    }
}
