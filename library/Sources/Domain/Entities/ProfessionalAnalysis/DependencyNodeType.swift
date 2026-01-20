import Foundation

/// Dependency node type
/// Following Single Responsibility Principle - represents graph node type
public enum DependencyNodeType: String, Sendable, Codable {
    case component
    case service
    case module
    case external
}
