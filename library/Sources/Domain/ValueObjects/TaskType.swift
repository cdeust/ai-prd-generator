import Foundation

/// Task context detection
/// Domain value object for task classification
public enum TaskType: String, Sendable, Codable {
    case newFeature
    case bugFix
    case refactoring
    case infrastructure
    case documentation
    case testing
    case unknown

    public var displayName: String {
        switch self {
        case .newFeature: return "New Feature"
        case .bugFix: return "Bug Fix"
        case .refactoring: return "Refactoring"
        case .infrastructure: return "Infrastructure"
        case .documentation: return "Documentation"
        case .testing: return "Testing"
        case .unknown: return "Unknown"
        }
    }
}
