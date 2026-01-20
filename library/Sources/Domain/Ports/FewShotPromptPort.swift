import Foundation

/// Port for selecting optimal few-shot examples for prompt engineering.
///
/// Few-shot learning improves PRD quality by providing relevant examples:
/// - Semantic similarity to current task
/// - Diversity across example types
/// - Quality-filtered examples only
///
/// Used for:
/// - Section generation prompts
/// - Reasoning task examples
/// - Quality benchmarking
public protocol FewShotPromptPort: Sendable {
    /// Select few-shot examples similar to input
    ///
    /// - Parameters:
    ///   - input: Input text to find similar examples for
    ///   - count: Number of examples to select
    ///   - category: Optional category filter
    /// - Returns: Selected examples sorted by relevance
    /// - Throws: If selection fails
    func selectExamples(
        similarTo input: String,
        count: Int,
        category: String?
    ) async throws -> [FewShotPromptExample]

    /// Select examples for specific section type
    ///
    /// - Parameters:
    ///   - sectionType: PRD section type
    ///   - count: Number of examples to select
    /// - Returns: Section-specific examples
    /// - Throws: If selection fails
    func selectForSection(
        type sectionType: SectionType,
        count: Int
    ) async throws -> [FewShotPromptExample]
}
