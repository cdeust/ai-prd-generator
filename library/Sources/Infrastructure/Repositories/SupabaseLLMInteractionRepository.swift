import Foundation
import Domain

/// Supabase implementation of LLM interaction tracking
/// Single Responsibility: LLM interaction persistence via Supabase
public final class SupabaseLLMInteractionRepository: LLMInteractionTrackerPort, @unchecked Sendable {
    private let databaseClient: SupabaseDatabasePort
    private let mapper: IntelligenceMapper
    private let tableName = "llm_interaction_traces"

    public init(databaseClient: SupabaseDatabasePort) {
        self.databaseClient = databaseClient
        self.mapper = IntelligenceMapper()
    }

    public func recordInteraction(_ trace: LLMInteractionTrace) async throws {
        let record = mapper.toRecord(trace)
        _ = try await databaseClient.insert(table: tableName, values: record)
    }

    public func updatePrdId(sectionId: UUID, prdId: UUID) async throws {
        let filter = QueryFilter(
            field: "section_id",
            operation: .equals,
            value: sectionId.uuidString.lowercased()
        )
        let update = ["prd_id": prdId.uuidString.lowercased()]
        _ = try await databaseClient.update(table: tableName, values: update, matching: filter)
    }

    public func updatePhase1PrdId(prdId: UUID) async throws {
        // Update all LLM traces where prd_id is currently null
        // PostgREST syntax: ?prd_id=is.null
        // We call this immediately after PRD creation, so it only affects current generation session
        let parameters: [String: Any] = ["new_prd_id": prdId.uuidString.lowercased()]
        _ = try await databaseClient.callRPC(
            function: "update_phase1_llm_traces",
            parameters: parameters
        )
    }

    public func findByPrdId(_ prdId: UUID) async throws -> [LLMInteractionTrace] {
        let filter = QueryFilter(
            field: "prd_id",
            operation: .equals,
            value: prdId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseLLMInteractionRecord].self, from: data)
        return records.compactMap { mapper.toDomain($0) }
    }

    public func findBySectionId(_ sectionId: UUID) async throws -> [LLMInteractionTrace] {
        let filter = QueryFilter(
            field: "section_id",
            operation: .equals,
            value: sectionId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseLLMInteractionRecord].self, from: data)
        return records.compactMap { mapper.toDomain($0) }
    }

    public func findByPurpose(_ purpose: InteractionPurpose, limit: Int) async throws -> [LLMInteractionTrace] {
        let filter = QueryFilter(
            field: "purpose",
            operation: .equals,
            value: purpose.rawValue
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseLLMInteractionRecord].self, from: data)
        return Array(records.compactMap { mapper.toDomain($0) }.prefix(limit))
    }

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
