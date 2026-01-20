import Foundation

/// Category of clarification question for intelligence tracking
public enum ClarificationCategory: String, Sendable, Codable, CaseIterable {
    case technical = "technical"
    case business = "business"
    case ux = "ux"
    case constraints = "constraints"
    case scope = "scope"
    case priorities = "priorities"
}
