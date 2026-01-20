import Foundation

/// Port for detecting information gaps in PRD generation.
///
/// Defines the interface for gap detection implementations that can identify
/// missing information from PRD drafts, user requirements, mockups, and codebase context.
public protocol GapDetectionPort: Sendable {
    /// Detect information gaps from a PRD draft.
    ///
    /// Analyzes the draft PRD content to identify missing or unclear information
    /// that would prevent generating a complete, high-quality PRD.
    ///
    /// - Parameters:
    ///   - draft: The current PRD draft text
    ///   - sections: Expected sections for the PRD
    ///   - context: Additional context (mockups, codebase, user requirements)
    /// - Returns: Array of detected information gaps
    /// - Throws: `GapResolutionError` if detection fails
    func detectGaps(
        in draft: String,
        expectedSections: [String],
        context: GapDetectionContext
    ) async throws -> [InformationGap]

    /// Categorize a detected gap.
    ///
    /// Analyzes the gap question and context to determine its category
    /// (authentication, data model, UX, etc.) for targeted resolution.
    ///
    /// - Parameter gap: The gap to categorize
    /// - Returns: Updated gap with category assigned
    /// - Throws: `GapResolutionError` if categorization fails
    func categorizeGap(_ gap: InformationGap) async throws -> InformationGap

    /// Determine priority for a detected gap.
    ///
    /// Analyzes the gap's impact on PRD quality and completeness to assign
    /// an appropriate priority level (critical, high, medium, low).
    ///
    /// - Parameter gap: The gap to prioritize
    /// - Returns: Updated gap with priority assigned
    /// - Throws: `GapResolutionError` if prioritization fails
    func prioritizeGap(_ gap: InformationGap) async throws -> InformationGap
}
