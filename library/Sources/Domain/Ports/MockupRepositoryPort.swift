import Foundation

/// Port for mockup persistence operations
/// Following Dependency Inversion - domain defines interface, infrastructure implements
public protocol MockupRepositoryPort: Sendable {
    /// Save a mockup
    func save(_ mockup: Mockup) async throws -> Mockup

    /// Save multiple mockups
    func saveBatch(_ mockups: [Mockup]) async throws -> [Mockup]

    /// Find mockup by ID
    func findById(_ id: UUID) async throws -> Mockup?

    /// Find all mockups for a PRD document
    func findByPRDDocumentId(_ prdDocumentId: UUID) async throws -> [Mockup]

    /// Update a mockup
    func update(_ mockup: Mockup) async throws -> Mockup

    /// Update mockup with analysis result
    func updateAnalysisResult(mockupId: UUID, analysisResult: MockupAnalysisResult) async throws

    /// Delete a mockup
    func delete(_ id: UUID) async throws

    /// Delete all mockups for a PRD document
    func deleteByPRDDocumentId(_ prdDocumentId: UUID) async throws
}
