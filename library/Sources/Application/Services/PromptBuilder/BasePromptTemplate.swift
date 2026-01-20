import Foundation
import Domain

/// Base prompt template for PRD generation
/// Application layer - Uses application DTOs to build prompts
public struct BasePromptTemplate {
    /// Build the base PRD generation prompt
    /// - Parameters:
    ///   - title: Project title
    ///   - description: Project description
    ///   - requirements: Project requirements
    /// - Returns: Formatted prompt string
    public static func build(
        title: String,
        description: String,
        requirements: [Requirement]
    ) -> String {
        """
        Generate a comprehensive Product Requirements Document (PRD) for the following project:

        # Project Title
        \(title)

        # Project Description
        \(description)

        # Requirements
        \(formatRequirements(requirements))

        # Instructions
        Create a detailed PRD with the following sections:
        1. Overview
        2. Goals & Objectives
        3. Requirements (Functional & Non-Functional)
        4. User Stories
        5. Technical Specification
        6. Data Model
        7. API Specification (if applicable)
        8. Security Considerations
        9. Performance Requirements
        10. Testing Strategy
        11. Deployment Plan
        12. Risks & Mitigation
        13. Timeline & Milestones

        Format the output in Markdown.
        """
    }

    private static func formatRequirements(_ requirements: [Requirement]) -> String {
        requirements
            .map { "- \($0.description) (Priority: \($0.priority.displayName))" }
            .joined(separator: "\n")
    }
}
