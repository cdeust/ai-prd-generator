import Foundation

/// Visual feedback type
public enum VisualFeedback: String, Sendable, Codable {
    case highlight = "Highlight"
    case animation = "Animation"
    case colorChange = "Color Change"
    case transition = "Transition"
    case toast = "Toast"
    case alert = "Alert"
    case spinner = "Spinner"
}
