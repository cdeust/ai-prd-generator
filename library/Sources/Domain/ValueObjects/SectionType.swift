import Foundation

/// Value object representing PRD section types
/// Following Open/Closed Principle - extensible via new cases
/// Note: rawValue uses snake_case for database compatibility with prd_section_type enum
public enum SectionType: String, Sendable, Codable, CaseIterable {
    case overview = "overview"
    case goals = "goals"
    case requirements = "requirements"
    case userStories = "user_stories"
    case technicalSpecification = "technical_specification"
    case acceptanceCriteria = "acceptance_criteria"
    case dataModel = "data_model"
    case apiSpecification = "api_specification"
    case securityConsiderations = "security_considerations"
    case performanceRequirements = "performance_requirements"
    case testing = "testing"
    case deployment = "deployment"
    case risks = "risks"
    case timeline = "timeline"

    public var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .goals: return "Goals & Objectives"
        case .requirements: return "Requirements"
        case .userStories: return "User Stories"
        case .technicalSpecification: return "Technical Specification"
        case .acceptanceCriteria: return "Acceptance Criteria"
        case .dataModel: return "Data Model"
        case .apiSpecification: return "API Specification"
        case .securityConsiderations: return "Security Considerations"
        case .performanceRequirements: return "Performance Requirements"
        case .testing: return "Testing Strategy"
        case .deployment: return "Deployment Plan"
        case .risks: return "Risks & Mitigation"
        case .timeline: return "Timeline & Milestones"
        }
    }

    public var order: Int {
        switch self {
        case .overview: return 0
        case .goals: return 1
        case .requirements: return 2
        case .userStories: return 3
        case .technicalSpecification: return 4
        case .acceptanceCriteria: return 5
        case .dataModel: return 6
        case .apiSpecification: return 7
        case .securityConsiderations: return 8
        case .performanceRequirements: return 9
        case .testing: return 10
        case .deployment: return 11
        case .risks: return 12
        case .timeline: return 13
        }
    }
}
