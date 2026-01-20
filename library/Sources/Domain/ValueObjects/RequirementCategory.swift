import Foundation

/// Value object representing requirement categories
public enum RequirementCategory: String, Sendable, Codable, CaseIterable {
    case functional
    case nonFunctional
    case technical
    case security
    case performance
    case ui
    case ux
    case accessibility
    case compliance

    public var displayName: String {
        switch self {
        case .functional: return "Functional"
        case .nonFunctional: return "Non-Functional"
        case .technical: return "Technical"
        case .security: return "Security"
        case .performance: return "Performance"
        case .ui: return "User Interface"
        case .ux: return "User Experience"
        case .accessibility: return "Accessibility"
        case .compliance: return "Compliance"
        }
    }
}
