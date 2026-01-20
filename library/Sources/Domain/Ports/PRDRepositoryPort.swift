import Foundation

/// Port for PRD persistence
/// Domain defines the interface, Infrastructure implements it
/// Following Interface Segregation Principle - focused interface
public protocol PRDRepositoryPort: Sendable {
    /// Save a PRD document
    func save(_ document: PRDDocument) async throws -> PRDDocument

    /// Find PRD by ID
    func findById(_ id: UUID) async throws -> PRDDocument?

    /// Find all PRDs
    func findAll(limit: Int, offset: Int) async throws -> [PRDDocument]

    /// Update existing PRD
    func update(_ document: PRDDocument) async throws -> PRDDocument

    /// Delete PRD
    func delete(_ id: UUID) async throws

    /// Search PRDs by title or content
    func search(query: String, limit: Int) async throws -> [PRDDocument]
}
