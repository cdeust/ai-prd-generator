import Foundation

/// UI element type classification
/// Following Single Responsibility Principle - represents UI element type
public enum UIElementType: String, Sendable, Codable {
    case button
    case textField
    case label
    case image
    case list
    case navigationBar
    case tabBar
    case other
}
