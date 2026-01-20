import Foundation

/// Test category classification
/// Following Single Responsibility Principle - represents test category
public enum TestCategory: String, Sendable, Codable {
    case unit
    case integration
    case e2e
    case performance
    case security
    case accessibility
}
