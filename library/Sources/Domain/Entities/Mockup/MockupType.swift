import Foundation

/// Mockup type classification
/// Following Single Responsibility Principle - represents mockup type enum
public enum MockupType: String, Sendable, Codable {
    case wireframe
    case mockup
    case prototype
    case screenshot
}
