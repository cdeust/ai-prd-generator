import Foundation

/// Challenge severity levels
/// Domain value object for severity classification
public enum ChallengeSeverity: String, Sendable, Codable {
    case critical
    case high
    case medium
    case low

    public var displayName: String {
        rawValue.capitalized
    }

    public var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}
