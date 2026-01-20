import Foundation

/// Visual state of a UI component
public enum ComponentState: String, Sendable, Codable {
    case enabled = "Enabled"
    case disabled = "Disabled"
    case selected = "Selected"
    case unselected = "Unselected"
    case focused = "Focused"
    case hovered = "Hovered"
    case pressed = "Pressed"
    case loading = "Loading"
    case error = "Error"
    case success = "Success"
    case warning = "Warning"
}
