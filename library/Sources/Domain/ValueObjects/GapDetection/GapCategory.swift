import Foundation

/// Categories of information gaps in PRD generation.
///
/// Classifies missing information by domain area to enable targeted
/// resolution strategies. Each category has specific resolution approaches
/// that work best for that type of information.
public enum GapCategory: String, Codable, Sendable, CaseIterable {
    /// Authentication and authorization requirements
    /// - Resolution: Codebase search for existing auth, reasoning for new requirements
    case authentication

    /// Data models, schemas, and persistence requirements
    /// - Resolution: Codebase search for existing models, mockup analysis for forms
    case dataModel

    /// Performance, scalability, and capacity requirements
    /// - Resolution: Reasoning based on similar systems, codebase patterns
    case scalability

    /// User experience, workflows, and interaction patterns
    /// - Resolution: Mockup analysis, existing UX patterns from codebase
    case userExperience

    /// Third-party integrations and external services
    /// - Resolution: Codebase search for existing integrations, API documentation
    case integration

    /// Security, privacy, and compliance requirements
    /// - Resolution: Reasoning from best practices, codebase security patterns
    case security

    /// Business rules, validation logic, and workflows
    /// - Resolution: Reasoning from requirements, codebase business logic
    case businessLogic

    /// Deployment, infrastructure, and operational requirements
    /// - Resolution: Codebase deployment configs, reasoning from architecture
    case deployment
}

extension GapCategory {
    /// Human-readable description of the gap category.
    public var description: String {
        switch self {
        case .authentication:
            return "Authentication & Authorization"
        case .dataModel:
            return "Data Models & Schemas"
        case .scalability:
            return "Performance & Scalability"
        case .userExperience:
            return "User Experience & Workflows"
        case .integration:
            return "Third-Party Integrations"
        case .security:
            return "Security & Privacy"
        case .businessLogic:
            return "Business Rules & Logic"
        case .deployment:
            return "Deployment & Infrastructure"
        }
    }

    /// Recommended resolution strategies for this category.
    public var preferredStrategies: [ResolutionStrategy] {
        switch self {
        case .authentication, .dataModel, .integration:
            // Code patterns likely exist
            return [.codebaseSearch, .reasoning, .mockupAnalysis]
        case .userExperience:
            // Visual and interaction patterns
            return [.mockupAnalysis, .codebaseSearch, .reasoning]
        case .scalability, .security, .deployment:
            // Requires reasoning and best practices
            return [.reasoning, .codebaseSearch, .informedAssumption]
        case .businessLogic:
            // Mix of requirements and code patterns
            return [.reasoning, .codebaseSearch, .informedAssumption]
        }
    }
}
