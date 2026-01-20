import Foundation

/// Action that can be performed on a UI component
public enum ComponentAction: String, Sendable, Codable {
    case tap = "Tap"
    case doubleTap = "Double Tap"
    case longPress = "Long Press"
    case swipeLeft = "Swipe Left"
    case swipeRight = "Swipe Right"
    case swipeUp = "Swipe Up"
    case swipeDown = "Swipe Down"
    case scroll = "Scroll"
    case drag = "Drag"
    case pinch = "Pinch"
    case rotate = "Rotate"
    case focus = "Focus"
    case blur = "Blur"
    case hover = "Hover"
    case input = "Input"
    case select = "Select"
    case submit = "Submit"
}
