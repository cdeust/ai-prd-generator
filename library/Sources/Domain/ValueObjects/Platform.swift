import Foundation

/// Platform types
/// Domain value object for platform classification
public enum Platform: String, Sendable, Codable {
    case ios
    case android
    case web
    case backend
    case desktop
    case crossPlatform
}
