import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// In-memory implementation of MockupRepositoryPort
/// For testing, demos, and rapid prototyping
/// Thread-safe using actor isolation
public actor InMemoryMockupRepository: MockupRepositoryPort {
    private var mockups: [UUID: Mockup] = [:]
    private var mockupsByPRD: [UUID: Set<UUID>] = [:]

    public init() {}

    public func save(_ mockup: Mockup) async throws -> Mockup {
        mockups[mockup.id] = mockup
        if let prdId = mockup.prdDocumentId {
            mockupsByPRD[prdId, default: []].insert(mockup.id)
        }
        return mockup
    }

    public func saveBatch(_ mockups: [Mockup]) async throws -> [Mockup] {
        var saved: [Mockup] = []
        for mockup in mockups {
            let result = try await save(mockup)
            saved.append(result)
        }
        return saved
    }

    public func findById(_ id: UUID) async throws -> Mockup? {
        mockups[id]
    }

    public func findByPRDDocumentId(_ prdDocumentId: UUID) async throws -> [Mockup] {
        let ids = mockupsByPRD[prdDocumentId] ?? []
        return ids.compactMap { mockups[$0] }.sorted { $0.orderIndex < $1.orderIndex }
    }

    public func update(_ mockup: Mockup) async throws -> Mockup {
        guard mockups[mockup.id] != nil else {
            throw RepositoryError.updateFailed("Mockup not found: \(mockup.id)")
        }
        mockups[mockup.id] = mockup
        return mockup
    }

    public func updateAnalysisResult(mockupId: UUID, analysisResult: MockupAnalysisResult) async throws {
        guard var mockup = mockups[mockupId] else {
            throw RepositoryError.updateFailed("Mockup not found: \(mockupId)")
        }
        mockup = Mockup(
            id: mockup.id,
            prdDocumentId: mockup.prdDocumentId,
            name: mockup.name,
            description: mockup.description,
            type: mockup.type,
            source: mockup.source,
            fileUrl: mockup.fileUrl,
            fileSize: mockup.fileSize,
            width: mockup.width,
            height: mockup.height,
            extractedElements: mockup.extractedElements,
            annotations: mockup.annotations,
            analysisResult: analysisResult,
            orderIndex: mockup.orderIndex,
            createdAt: mockup.createdAt,
            updatedAt: Date()
        )
        mockups[mockupId] = mockup
    }

    public func delete(_ id: UUID) async throws {
        guard let mockup = mockups[id] else {
            throw RepositoryError.deleteFailed("Mockup not found: \(id)")
        }
        if let prdId = mockup.prdDocumentId {
            mockupsByPRD[prdId]?.remove(id)
        }
        mockups.removeValue(forKey: id)
    }

    public func deleteByPRDDocumentId(_ prdDocumentId: UUID) async throws {
        let ids = mockupsByPRD[prdDocumentId] ?? []
        for id in ids {
            mockups.removeValue(forKey: id)
        }
        mockupsByPRD.removeValue(forKey: prdDocumentId)
    }
}
