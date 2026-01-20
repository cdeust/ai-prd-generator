import Foundation

/// Dependency graph edge
/// Following Single Responsibility Principle - represents graph edge
public struct DependencyEdge: Identifiable, Sendable, Codable {
    public let id: UUID
    public let from: UUID
    public let to: UUID
    public let type: DependencyEdgeType

    public init(id: UUID = UUID(), from: UUID, to: UUID, type: DependencyEdgeType) {
        self.id = id
        self.from = from
        self.to = to
        self.type = type
    }
}
