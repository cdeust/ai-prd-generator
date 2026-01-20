import Foundation

/// Trigger that initiates an interaction
public enum InteractionTrigger: String, Sendable, Codable {
    case tap = "Tap"
    case doubleTap = "Double Tap"
    case longPress = "Long Press"
    case swipe = "Swipe"
    case scroll = "Scroll"
    case drag = "Drag"
    case input = "Input"
    case submit = "Submit"
    case focus = "Focus"
    case blur = "Blur"
    case load = "Load"
    case timer = "Timer"
    case gesture = "Gesture"
    case keyboard = "Keyboard"
    case voice = "Voice"
}
