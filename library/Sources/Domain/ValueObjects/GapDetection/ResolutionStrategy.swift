import Foundation

/// Strategies for resolving information gaps in PRD generation.
///
/// Each strategy represents a different approach to finding missing information,
/// with varying levels of confidence and accuracy. Strategies can be combined
/// for comprehensive gap resolution.
public enum ResolutionStrategy: String, Codable, Sendable, CaseIterable {
    /// Use chain-of-thought reasoning to infer missing information
    /// - Confidence: Medium (60-80%)
    /// - Best for: Architecture decisions, scalability patterns, best practices
    /// - Speed: Fast
    case reasoning

    /// Search the codebase for existing patterns and implementations
    /// - Confidence: High (85-95%)
    /// - Best for: Data models, authentication, integrations, existing features
    /// - Speed: Medium
    case codebaseSearch

    /// Analyze mockups for UI/UX requirements and data structures
    /// - Confidence: High (80-90%)
    /// - Best for: User flows, UI components, form fields, interaction patterns
    /// - Speed: Medium
    case mockupAnalysis

    /// Ask the user for clarification
    /// - Confidence: Highest (100%)
    /// - Best for: Business rules, priorities, constraints
    /// - Speed: Depends on user
    case userQuery

    /// Make an informed assumption based on context
    /// - Confidence: Low (40-60%)
    /// - Best for: Non-critical details, standard patterns
    /// - Speed: Fast
    case informedAssumption
}

extension ResolutionStrategy {
    /// Human-readable description of the resolution strategy.
    public var description: String {
        switch self {
        case .reasoning:
            return "Chain-of-Thought Reasoning"
        case .codebaseSearch:
            return "Codebase Pattern Search (ReAct)"
        case .mockupAnalysis:
            return "Mockup Analysis (Vision)"
        case .userQuery:
            return "User Clarification"
        case .informedAssumption:
            return "Informed Assumption"
        }
    }

    /// Expected confidence range for this strategy.
    public var expectedConfidence: ClosedRange<Double> {
        switch self {
        case .reasoning:
            return 0.60...0.80
        case .codebaseSearch:
            return 0.85...0.95
        case .mockupAnalysis:
            return 0.80...0.90
        case .userQuery:
            return 1.00...1.00
        case .informedAssumption:
            return 0.40...0.60
        }
    }

    /// Relative cost of executing this strategy.
    public var cost: StrategyCost {
        switch self {
        case .reasoning, .informedAssumption:
            return .low
        case .codebaseSearch, .mockupAnalysis:
            return .medium
        case .userQuery:
            return .high
        }
    }
}
