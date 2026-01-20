import Foundation

/// Mockup source location
/// Following Single Responsibility Principle - represents mockup source
public enum MockupSource: Sendable, Codable {
    case file(path: String)
    case url(String)
    case base64(String)
}
