import Foundation

/// Edge connecting context nodes in graph
/// Following Single Responsibility: Represents relationship between contexts
public struct ContextEdge: Identifiable, Sendable {
    public let id: UUID
    public let source: UUID
    public let target: UUID
    public let relationship: ContextRelationship
    public let strength: Double // 0.0-1.0
    public let timestamp: Date

    public init(
        id: UUID,
        source: UUID,
        target: UUID,
        relationship: ContextRelationship,
        strength: Double,
        timestamp: Date
    ) {
        self.id = id
        self.source = source
        self.target = target
        self.relationship = relationship
        self.strength = strength
        self.timestamp = timestamp
    }
}
