import Foundation
import Domain

/// DTO representing a requirement within a PRD request
/// Following Single Responsibility Principle - encapsulates requirement data
public struct Requirement: Identifiable, Sendable {
    public let id: UUID
    public let description: String
    public let priority: Priority
    public let category: RequirementCategory

    public init(
        id: UUID = UUID(),
        description: String,
        priority: Priority,
        category: RequirementCategory
    ) {
        self.id = id
        self.description = description
        self.priority = priority
        self.category = category
    }
}
