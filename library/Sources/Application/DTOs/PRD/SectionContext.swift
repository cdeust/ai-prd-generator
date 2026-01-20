import Foundation
import Domain

/// Context for generating a single PRD section
///
/// Contains ONLY information relevant to this specific section,
/// keeping prompts under 8K tokens for Apple Intelligence compatibility.
///
/// **Usage:**
/// ```swift
/// let context = SectionContext(
///     title: "Trading Bot",
///     description: "Autonomous trading...",
///     relevantContext: "Key Requirements:\n- Real-time data...",
///     sectionType: .overview
/// )
/// ```
public struct SectionContext: Sendable {
    public let title: String
    public let description: String
    public let relevantContext: String
    public let sectionType: SectionType

    public init(
        title: String,
        description: String,
        relevantContext: String,
        sectionType: SectionType
    ) {
        self.title = title
        self.description = description
        self.relevantContext = relevantContext
        self.sectionType = sectionType
    }
}
