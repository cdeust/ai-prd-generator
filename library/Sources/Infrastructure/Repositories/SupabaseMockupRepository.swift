import Foundation
import Domain

/// Supabase implementation of MockupRepositoryPort
/// Following Single Responsibility: Mockup persistence via Supabase
public final class SupabaseMockupRepository: MockupRepositoryPort, Sendable {
    private let databaseClient: SupabaseDatabasePort
    private let mapper: SupabaseMockupMapper

    public init(databaseClient: SupabaseDatabasePort) {
        self.databaseClient = databaseClient
        self.mapper = SupabaseMockupMapper()
    }

    public func save(_ mockup: Mockup) async throws -> Mockup {
        let record = mapper.toRecord(mockup)
        let data = try await databaseClient.insert(table: "mockups", values: record)
        let savedRecords = try decode([SupabaseMockupRecord].self, from: data)
        guard let saved = savedRecords.first else {
            throw RepositoryError.saveFailed("No record returned after insert")
        }
        return mapper.toDomain(saved)
    }

    public func saveBatch(_ mockups: [Mockup]) async throws -> [Mockup] {
        guard !mockups.isEmpty else { return [] }
        let records = mockups.map { mapper.toRecord($0) }
        let data = try await databaseClient.insertBatch(table: "mockups", values: records)
        let savedRecords = try decode([SupabaseMockupRecord].self, from: data)
        return savedRecords.map { mapper.toDomain($0) }
    }

    public func findById(_ id: UUID) async throws -> Mockup? {
        let filter = QueryFilter(field: "id", operation: .equals, value: id.uuidString)
        let data = try await databaseClient.select(from: "mockups", columns: nil, filter: filter)
        let records = try decode([SupabaseMockupRecord].self, from: data)
        return records.first.map { mapper.toDomain($0) }
    }

    public func findByPRDDocumentId(_ prdDocumentId: UUID) async throws -> [Mockup] {
        let filter = QueryFilter(field: "prd_document_id", operation: .equals, value: prdDocumentId.uuidString)
        let data = try await databaseClient.select(from: "mockups", columns: nil, filter: filter)
        let records = try decode([SupabaseMockupRecord].self, from: data)
        return records.map { mapper.toDomain($0) }.sorted { $0.orderIndex < $1.orderIndex }
    }

    public func update(_ mockup: Mockup) async throws -> Mockup {
        let record = mapper.toRecord(mockup)
        let filter = QueryFilter(field: "id", operation: .equals, value: mockup.id.uuidString)
        let data = try await databaseClient.update(table: "mockups", values: record, matching: filter)
        let updatedRecords = try decode([SupabaseMockupRecord].self, from: data)
        guard let updated = updatedRecords.first else {
            throw RepositoryError.updateFailed("No record returned after update")
        }
        return mapper.toDomain(updated)
    }

    public func updateAnalysisResult(mockupId: UUID, analysisResult: MockupAnalysisResult) async throws {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(analysisResult)
        let jsonString = String(data: jsonData, encoding: .utf8)

        let updateData = MockupAnalysisUpdate(analysisResultJson: jsonString, updatedAt: Date())
        let filter = QueryFilter(field: "id", operation: .equals, value: mockupId.uuidString)
        _ = try await databaseClient.update(table: "mockups", values: updateData, matching: filter)
    }

    public func delete(_ id: UUID) async throws {
        let filter = QueryFilter(field: "id", operation: .equals, value: id.uuidString)
        try await databaseClient.delete(from: "mockups", matching: filter)
    }

    public func deleteByPRDDocumentId(_ prdDocumentId: UUID) async throws {
        let filter = QueryFilter(field: "prd_document_id", operation: .equals, value: prdDocumentId.uuidString)
        try await databaseClient.delete(from: "mockups", matching: filter)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}

// MARK: - Update DTOs

private struct MockupAnalysisUpdate: Codable {
    let analysisResultJson: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case analysisResultJson = "analysis_result_json"
        case updatedAt = "updated_at"
    }
}
