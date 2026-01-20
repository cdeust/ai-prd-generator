import Foundation

/// Conflict types
/// Domain value object for architectural conflicts
public enum ConflictType: String, Sendable, Codable {
    case layerViolation
    case circularDependency
    case tightCoupling
    case missingAbstraction
    case solidViolation

    public var displayName: String {
        switch self {
        case .layerViolation: return "Layer Violation"
        case .circularDependency: return "Circular Dependency"
        case .tightCoupling: return "Tight Coupling"
        case .missingAbstraction: return "Missing Abstraction"
        case .solidViolation: return "SOLID Violation"
        }
    }
}
