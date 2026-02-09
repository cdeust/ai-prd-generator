import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// In-memory mock PRD repository for testing
public actor MockPRDRepository: PRDRepositoryPort {
    private var documents: [UUID: PRDDocument] = [:]
    private var saveCount = 0
    private var shouldFail = false
    private var failureError: Error?

    public init() {}

    // MARK: - Configuration

    public func configure(shouldFail: Bool, error: Error? = nil) {
        self.shouldFail = shouldFail
        self.failureError = error
    }

    public func reset() {
        documents.removeAll()
        saveCount = 0
        shouldFail = false
        failureError = nil
    }

    public func getSaveCount() -> Int {
        saveCount
    }

    // MARK: - PRDRepositoryPort

    public func save(_ document: PRDDocument) async throws -> PRDDocument {
        saveCount += 1

        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }

        documents[document.id] = document
        return document
    }

    public func findById(_ id: UUID) async throws -> PRDDocument? {
        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }
        return documents[id]
    }

    public func findAll(limit: Int, offset: Int) async throws -> [PRDDocument] {
        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }

        let sorted = documents.values.sorted { $0.createdAt > $1.createdAt }
        let start = min(offset, sorted.count)
        let end = min(start + limit, sorted.count)

        return Array(sorted[start..<end])
    }

    public func update(_ document: PRDDocument) async throws -> PRDDocument {
        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }

        guard documents[document.id] != nil else {
            throw MockRepositoryError.notFound
        }

        documents[document.id] = document
        return document
    }

    public func delete(_ id: UUID) async throws {
        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }

        documents.removeValue(forKey: id)
    }

    public func search(query: String, limit: Int) async throws -> [PRDDocument] {
        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }

        let lowercased = query.lowercased()
        let matching = documents.values.filter { doc in
            doc.title.lowercased().contains(lowercased) ||
            doc.sections.contains { section in
                section.content.lowercased().contains(lowercased)
            }
        }

        return Array(matching.prefix(limit))
    }
}

// MARK: - Mock Errors

public enum MockRepositoryError: Error, Sendable {
    case configured
    case notFound
    case alreadyExists
}
