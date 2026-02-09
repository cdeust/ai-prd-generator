import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// In-memory implementation of PRDRepositoryPort
/// For testing, demos, and rapid prototyping
/// Thread-safe using actor isolation
public actor InMemoryPRDRepository: PRDRepositoryPort {
    private var documents: [UUID: PRDDocument] = [:]

    public init() {}

    public func save(_ document: PRDDocument) async throws -> PRDDocument {
        documents[document.id] = document
        return document
    }

    public func findById(_ id: UUID) async throws -> PRDDocument? {
        return documents[id]
    }

    public func findAll(limit: Int, offset: Int) async throws -> [PRDDocument] {
        let sorted = documents.values.sorted { $0.createdAt > $1.createdAt }

        guard offset < sorted.count else {
            return []
        }

        let end = min(offset + limit, sorted.count)
        return Array(sorted[offset..<end])
    }

    public func update(_ document: PRDDocument) async throws -> PRDDocument {
        guard documents[document.id] != nil else {
            throw RepositoryError.invalidQuery("Document not found: \(document.id)")
        }

        documents[document.id] = document
        return document
    }

    public func delete(_ id: UUID) async throws {
        guard documents[id] != nil else {
            throw RepositoryError.invalidQuery("Document not found: \(id)")
        }

        documents.removeValue(forKey: id)
    }

    public func search(query: String, limit: Int) async throws -> [PRDDocument] {
        let lowercasedQuery = query.lowercased()

        let filtered = documents.values.filter { document in
            document.title.lowercased().contains(lowercasedQuery) ||
            document.sections.contains { section in
                section.title.lowercased().contains(lowercasedQuery) ||
                section.content.lowercased().contains(lowercasedQuery)
            }
        }

        let sorted = filtered.sorted { $0.createdAt > $1.createdAt }
        return Array(sorted.prefix(limit))
    }
}
