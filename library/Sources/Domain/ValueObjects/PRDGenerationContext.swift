import Foundation

/// Context for PRD generation used in adaptive verification
/// Single Responsibility: Captures PRD generation state for context-aware decisions
public struct PRDGenerationContext: Sendable {
    public let projectName: String
    public let sections: [PRDSection]
    public let hasAmbiguity: Bool

    public init(
        projectName: String,
        sections: [PRDSection],
        hasAmbiguity: Bool
    ) {
        self.projectName = projectName
        self.sections = sections
        self.hasAmbiguity = hasAmbiguity
    }

    /// Create new context with updated sections
    public func withSections(_ sections: [PRDSection]) -> PRDGenerationContext {
        PRDGenerationContext(
            projectName: projectName,
            sections: sections,
            hasAmbiguity: hasAmbiguity
        )
    }
}
