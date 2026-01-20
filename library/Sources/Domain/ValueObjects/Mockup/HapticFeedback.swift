import Foundation

/// Haptic feedback type
public enum HapticFeedback: String, Sendable, Codable {
    case light = "Light"
    case medium = "Medium"
    case heavy = "Heavy"
    case success = "Success"
    case warning = "Warning"
    case error = "Error"
    case selection = "Selection"
}
