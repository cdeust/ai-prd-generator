import Foundation

/// Test priority classification
/// Following Single Responsibility Principle - represents test priority
public enum TestPriority: String, Sendable, Codable {
    case critical
    case high
    case medium
    case low
}
