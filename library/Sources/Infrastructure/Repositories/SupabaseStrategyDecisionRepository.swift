import Foundation
import Domain

/// Supabase implementation of strategy decision tracking
/// Single Responsibility: Strategy decision persistence via Supabase
public final class SupabaseStrategyDecisionRepository: StrategyDecisionTrackerPort, @unchecked Sendable {
    private let databaseClient: SupabaseDatabasePort
    private let mapper: IntelligenceMapper
    private let tableName = "thinking_strategy_decisions"

    public init(databaseClient: SupabaseDatabasePort) {
        self.databaseClient = databaseClient
        self.mapper = IntelligenceMapper()
    }

    public func recordDecision(_ decision: ThinkingStrategyDecision) async throws {
        let record = mapper.toRecord(decision)
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

    public func updatePerformance(
        decisionId: UUID,
        performance: StrategyPerformance,
        wasEffective: Bool,
        lessonsLearned: String?
    ) async throws {
        let filter = QueryFilter(
            field: "id",
            operation: .equals,
            value: decisionId.uuidString.lowercased()
        )

        var perfDict: [String: Double] = [:]
        if let q = performance.qualityScore { perfDict["quality_score"] = q }
        if let e = performance.executionTimeSeconds { perfDict["execution_time_s"] = Double(e) }
        if let t = performance.tokensUsed { perfDict["tokens_used"] = Double(t) }

        let update = PerformanceUpdateDTO(
            actualPerformance: perfDict.isEmpty ? nil : perfDict,
            wasEffective: wasEffective,
            lessonsLearned: lessonsLearned,
            updatedAt: Date()
        )

        _ = try await databaseClient.update(table: tableName, values: update, matching: filter)
    }

    public func findByPrdId(_ prdId: UUID) async throws -> [ThinkingStrategyDecision] {
        let filter = QueryFilter(
            field: "prd_id",
            operation: .equals,
            value: prdId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseStrategyDecisionRecord].self, from: data)
        return records.compactMap { mapToDomain($0) }
    }

    public func findByStrategy(_ strategy: String, limit: Int) async throws -> [ThinkingStrategyDecision] {
        let filter = QueryFilter(
            field: "strategy_chosen",
            operation: .equals,
            value: strategy
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseStrategyDecisionRecord].self, from: data)
        return Array(records.compactMap { mapToDomain($0) }.prefix(limit))
    }

    public func findEffectiveStrategies(
        characteristics: InputCharacteristics,
        limit: Int
    ) async throws -> [ThinkingStrategyDecision] {
        let filter = QueryFilter(
            field: "was_effective",
            operation: .equals,
            value: "true"
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseStrategyDecisionRecord].self, from: data)
        return Array(records.compactMap { mapToDomain($0) }.prefix(limit))
    }

    private func mapToDomain(_ record: SupabaseStrategyDecisionRecord) -> ThinkingStrategyDecision? {
        guard let id = UUID(uuidString: record.id) else {
            return nil
        }

        return ThinkingStrategyDecision(
            id: id,
            prdId: record.prdId.flatMap { UUID(uuidString: $0) },
            sectionId: record.sectionId.flatMap { UUID(uuidString: $0) },
            strategyChosen: record.strategyChosen,
            reasoning: record.reasoning,
            confidenceScore: record.confidenceScore,
            inputCharacteristics: InputCharacteristics(),
            alternativesConsidered: record.alternativesConsidered ?? [],
            actualPerformance: nil,
            wasEffective: record.wasEffective,
            lessonsLearned: record.lessonsLearned,
            createdAt: record.createdAt ?? Date(),
            updatedAt: record.updatedAt ?? Date()
        )
    }

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
