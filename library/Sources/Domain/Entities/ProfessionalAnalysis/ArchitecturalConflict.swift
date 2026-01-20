import Foundation

/// Architectural conflict detected
/// Following Single Responsibility Principle - represents architectural conflict
public struct ArchitecturalConflict: Identifiable, Sendable, Codable {
    public let id: UUID
    public let conflictType: ConflictType
    public let description: String
    public let affectedComponents: [String]
    public let resolution: String?

    public init(
        id: UUID = UUID(),
        conflictType: ConflictType,
        description: String,
        affectedComponents: [String],
        resolution: String? = nil
    ) {
        self.id = id
        self.conflictType = conflictType
        self.description = description
        self.affectedComponents = affectedComponents
        self.resolution = resolution
    }
}
