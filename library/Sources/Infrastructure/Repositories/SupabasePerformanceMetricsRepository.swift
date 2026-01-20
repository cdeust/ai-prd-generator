import Foundation
import Domain

/// Supabase implementation of performance metrics tracking
/// Single Responsibility: Performance metrics persistence via Supabase
public final class SupabasePerformanceMetricsRepository: PerformanceMetricsTrackerPort, @unchecked Sendable {
    private let databaseClient: SupabaseDatabasePort
    private let mapper: IntelligenceMapper
    private let tableName = "prd_performance_metrics"

    public init(databaseClient: SupabaseDatabasePort) {
        self.databaseClient = databaseClient
        self.mapper = IntelligenceMapper()
    }

    public func saveMetrics(_ metrics: PRDPerformanceMetrics) async throws {
        let record = mapper.toRecord(metrics)
        _ = try await databaseClient.upsert(table: tableName, values: record, onConflict: ["prd_id"])
    }

    public func findByPrdId(_ prdId: UUID) async throws -> PRDPerformanceMetrics? {
        let filter = QueryFilter(
            field: "prd_id",
            operation: .equals,
            value: prdId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabasePerformanceMetricsRecord].self, from: data)
        return records.first.flatMap { mapToDomain($0) }
    }

    public func updateUserFeedback(
        prdId: UUID,
        satisfactionScore: Double,
        wouldRecommend: Bool,
        feedbackText: String?
    ) async throws {
        let filter = QueryFilter(
            field: "prd_id",
            operation: .equals,
            value: prdId.uuidString.lowercased()
        )

        let update = UserFeedbackUpdateDTO(
            userSatisfactionScore: satisfactionScore,
            userWouldRecommend: wouldRecommend,
            userFeedbackText: feedbackText,
            updatedAt: Date()
        )

        _ = try await databaseClient.update(table: tableName, values: update, matching: filter)
    }

    public func getAverageByStrategy(_ strategy: String) async throws -> PRDPerformanceMetrics? {
        let filter = QueryFilter(
            field: "strategy_used",
            operation: .equals,
            value: strategy
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabasePerformanceMetricsRecord].self, from: data)
        let metrics = records.compactMap { mapToDomain($0) }

        guard !metrics.isEmpty else { return nil }

        // Calculate averages
        let avgQuality = metrics.compactMap { $0.qualityScore }.average()
        let avgCompleteness = metrics.compactMap { $0.completenessScore }.average()
        let avgClarity = metrics.compactMap { $0.clarityScore }.average()
        let avgTechnical = metrics.compactMap { $0.technicalAccuracyScore }.average()

        return PRDPerformanceMetrics(
            prdId: UUID(),
            qualityScore: avgQuality,
            completenessScore: avgCompleteness,
            clarityScore: avgClarity,
            technicalAccuracyScore: avgTechnical,
            strategyUsed: strategy
        )
    }

    private func mapToDomain(_ record: SupabasePerformanceMetricsRecord) -> PRDPerformanceMetrics? {
        guard let id = UUID(uuidString: record.id),
              let prdId = UUID(uuidString: record.prdId) else {
            return nil
        }

        return PRDPerformanceMetrics(
            id: id,
            prdId: prdId,
            qualityScore: record.qualityScore,
            completenessScore: record.completenessScore,
            clarityScore: record.clarityScore,
            technicalAccuracyScore: record.technicalAccuracyScore,
            totalGenerationTimeSeconds: record.totalGenerationTimeS,
            totalTokensUsed: record.totalTokensUsed,
            totalCostUsd: record.totalCostUsd,
            strategyUsed: record.strategyUsed,
            strategyEffectiveness: record.strategyEffectiveness,
            ragQueriesCount: record.ragQueriesCount,
            ragChunksUsed: record.ragChunksUsed,
            ragRelevanceAvg: record.ragRelevanceAvg,
            userSatisfactionScore: record.userSatisfactionScore,
            userWouldRecommend: record.userWouldRecommend,
            userFeedbackText: record.userFeedbackText,
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

/// Extension for calculating averages
extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
