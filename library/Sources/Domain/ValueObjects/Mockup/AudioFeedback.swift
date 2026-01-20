import Foundation

/// Audio feedback type
public enum AudioFeedback: String, Sendable, Codable {
    case click = "Click"
    case beep = "Beep"
    case success = "Success"
    case error = "Error"
    case notification = "Notification"
}
