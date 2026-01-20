import Foundation

/// Animation type for screen transitions
public enum TransitionAnimation: String, Sendable, Codable {
    case push = "Push"
    case pop = "Pop"
    case present = "Present"
    case dismiss = "Dismiss"
    case fade = "Fade"
    case slide = "Slide"
    case zoom = "Zoom"
    case flip = "Flip"
    case none = "None"
}
