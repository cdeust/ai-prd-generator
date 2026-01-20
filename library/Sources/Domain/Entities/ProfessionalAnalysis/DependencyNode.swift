import Foundation

/// Dependency graph node
/// Following Single Responsibility Principle - represents graph node
public struct DependencyNode: Identifiable, Sendable, Codable {
    public let id: UUID
    public let name: String
    public let type: DependencyNodeType

    public init(id: UUID = UUID(), name: String, type: DependencyNodeType) {
        self.id = id
        self.name = name
        self.type = type
    }
}
