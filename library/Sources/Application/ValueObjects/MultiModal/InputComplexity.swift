import Foundation

/// Input complexity level based on provided data
public enum InputComplexity: String, Sendable, Equatable, Codable {
    /// Text only
    case low

    /// Text + mockups OR text + codebase
    case medium

    /// Text + mockups + codebase
    case high

    /// Human-readable description
    public var description: String {
        switch self {
        case .low:
            return "Low complexity (text only)"
        case .medium:
            return "Medium complexity (text + one context source)"
        case .high:
            return "High complexity (text + multiple context sources)"
        }
    }

    /// Estimated analysis time in seconds
    public var estimatedDurationSeconds: Int {
        switch self {
        case .low: return 5
        case .medium: return 15
        case .high: return 30
        }
    }
}
