import Foundation

/// Value object representing priority levels
/// Immutable, no identity - pure domain concept
public enum Priority: String, Sendable, Codable, CaseIterable {
    case critical
    case high
    case medium
    case low

    public var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }

    public var displayName: String {
        rawValue.capitalized
    }
}
