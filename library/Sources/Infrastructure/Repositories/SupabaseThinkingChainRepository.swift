import Foundation
import Domain

/// Supabase implementation of thinking chain step tracking
/// Single Responsibility: Thinking step persistence via Supabase
public final class SupabaseThinkingChainRepository: ThinkingChainTrackerPort, @unchecked Sendable {
    private let databaseClient: SupabaseDatabasePort
    private let mapper: IntelligenceMapper
    private let tableName = "thinking_chain_steps"

    public init(databaseClient: SupabaseDatabasePort) {
        self.databaseClient = databaseClient
        self.mapper = IntelligenceMapper()
    }

    public func recordStep(_ step: ThinkingChainStep) async throws {
        let record = mapper.toRecord(step)
        _ = try await databaseClient.insert(table: tableName, values: record)
    }

    public func recordSteps(_ steps: [ThinkingChainStep]) async throws {
        let records = steps.map { mapper.toRecord($0) }
        _ = try await databaseClient.insertBatch(table: tableName, values: records)
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

    public func findByPrdId(_ prdId: UUID) async throws -> [ThinkingChainStep] {
        let filter = QueryFilter(
            field: "prd_id",
            operation: .equals,
            value: prdId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseThinkingStepRecord].self, from: data)
        return records.compactMap { mapToDomain($0) }.sorted { $0.stepNumber < $1.stepNumber }
    }

    public func findBySectionId(_ sectionId: UUID) async throws -> [ThinkingChainStep] {
        let filter = QueryFilter(
            field: "section_id",
            operation: .equals,
            value: sectionId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseThinkingStepRecord].self, from: data)
        return records.compactMap { mapToDomain($0) }.sorted { $0.stepNumber < $1.stepNumber }
    }

    public func findByInteractionId(_ interactionId: UUID) async throws -> [ThinkingChainStep] {
        let filter = QueryFilter(
            field: "llm_interaction_id",
            operation: .equals,
            value: interactionId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseThinkingStepRecord].self, from: data)
        return records.compactMap { mapToDomain($0) }.sorted { $0.stepNumber < $1.stepNumber }
    }

    private func mapToDomain(_ record: SupabaseThinkingStepRecord) -> ThinkingChainStep? {
        guard let id = UUID(uuidString: record.id),
              let thoughtType = ThoughtStepType(rawValue: record.thoughtType) else {
            return nil
        }

        return ThinkingChainStep(
            id: id,
            prdId: record.prdId.flatMap { UUID(uuidString: $0) },
            sectionId: record.sectionId.flatMap { UUID(uuidString: $0) },
            llmInteractionId: record.llmInteractionId.flatMap { UUID(uuidString: $0) },
            stepNumber: record.stepNumber,
            thoughtType: thoughtType,
            content: record.content,
            evidenceUsed: [],
            confidence: record.confidence,
            tokensUsed: record.tokensUsed,
            executionTimeMs: record.executionTimeMs,
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
