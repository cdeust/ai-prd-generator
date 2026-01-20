import Foundation

/// Contradiction between assumptions
/// Following Single Responsibility: Represents assumption conflict only
public struct Contradiction: Identifiable, Sendable {
    public let id: UUID
    public let assumption1: UUID
    public let assumption2: UUID
    public let conflict: String
    public let resolution: String

    public init(
        id: UUID = UUID(),
        assumption1: UUID,
        assumption2: UUID,
        conflict: String,
        resolution: String
    ) {
        self.id = id
        self.assumption1 = assumption1
        self.assumption2 = assumption2
        self.conflict = conflict
        self.resolution = resolution
    }
}
