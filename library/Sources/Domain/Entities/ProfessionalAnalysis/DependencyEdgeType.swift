import Foundation

/// Dependency edge type
/// Following Single Responsibility Principle - represents graph edge type
public enum DependencyEdgeType: String, Sendable, Codable {
    case depends
    case uses
    case extends
    case implements
}
