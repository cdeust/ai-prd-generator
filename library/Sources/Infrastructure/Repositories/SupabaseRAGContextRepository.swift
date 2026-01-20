import Foundation
import Domain

/// Supabase implementation of RAG context tracking
/// Single Responsibility: RAG context persistence via Supabase
public final class SupabaseRAGContextRepository: RAGContextTrackerPort, @unchecked Sendable {
    private let databaseClient: SupabaseDatabasePort
    private let mapper: IntelligenceMapper
    private let tableName = "rag_context_traces"

    public init(databaseClient: SupabaseDatabasePort) {
        self.databaseClient = databaseClient
        self.mapper = IntelligenceMapper()
    }

    public func recordRetrieval(_ trace: RAGContextTrace) async throws {
        let record = mapper.toRecord(trace)
        _ = try await databaseClient.insert(table: tableName, values: record)
    }

    public func updatePrdId(codebaseId: UUID, prdId: UUID) async throws {
        let filter = QueryFilter(
            field: "codebase_id",
            operation: .equals,
            value: codebaseId.uuidString.lowercased()
        )
        let update = ["prd_id": prdId.uuidString.lowercased()]
        _ = try await databaseClient.update(table: tableName, values: update, matching: filter)
    }

    public func updateUsefulness(
        traceId: UUID,
        userFeedback: Bool,
        actualUsefulness: RAGUsefulness
    ) async throws {
        let filter = QueryFilter(
            field: "id",
            operation: .equals,
            value: traceId.uuidString.lowercased()
        )

        let update = UsefulnessUpdateDTO(
            userFeedback: userFeedback,
            actualUsefulness: actualUsefulness.rawValue
        )

        _ = try await databaseClient.update(table: tableName, values: update, matching: filter)
    }

    public func findByPrdId(_ prdId: UUID) async throws -> [RAGContextTrace] {
        let filter = QueryFilter(
            field: "prd_id",
            operation: .equals,
            value: prdId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseRAGContextRecord].self, from: data)
        return records.compactMap { mapToDomain($0) }
    }

    public func findByCodebaseId(_ codebaseId: UUID, limit: Int) async throws -> [RAGContextTrace] {
        let filter = QueryFilter(
            field: "codebase_id",
            operation: .equals,
            value: codebaseId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseRAGContextRecord].self, from: data)
        return Array(records.compactMap { mapToDomain($0) }.prefix(limit))
    }

    public func getAverageRelevance(codebaseId: UUID) async throws -> Double? {
        let traces = try await findByCodebaseId(codebaseId, limit: 1000)
        let allScores = traces.flatMap { $0.relevanceScores }
        guard !allScores.isEmpty else { return nil }
        return allScores.reduce(0, +) / Double(allScores.count)
    }

    private func mapToDomain(_ record: SupabaseRAGContextRecord) -> RAGContextTrace? {
        guard let id = UUID(uuidString: record.id),
              let codebaseId = UUID(uuidString: record.codebaseId),
              let queryType = RAGQueryType(rawValue: record.queryType),
              let retrievalMethod = RetrievalMethod(rawValue: record.retrievalMethod) else {
            return nil
        }

        return RAGContextTrace(
            id: id,
            prdId: record.prdId.flatMap { UUID(uuidString: $0) },
            sectionId: record.sectionId.flatMap { UUID(uuidString: $0) },
            codebaseId: codebaseId,
            llmInteractionId: record.llmInteractionId.flatMap { UUID(uuidString: $0) },
            query: record.query,
            queryType: queryType,
            retrievedChunks: [],
            chunkIds: record.chunkIds?.compactMap { UUID(uuidString: $0) } ?? [],
            relevanceScores: record.relevanceScores ?? [],
            retrievalMethod: retrievalMethod,
            reasoningForSelection: record.reasoningForSelection,
            impactOnOutput: record.impactOnOutput,
            userFeedback: record.userFeedback,
            actualUsefulness: record.actualUsefulness.flatMap { RAGUsefulness(rawValue: $0) },
            createdAt: record.createdAt ?? Date()
        )
    }

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
