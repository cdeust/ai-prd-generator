import Foundation
import Domain

/// Supabase implementation of clarification tracking
/// Single Responsibility: Clarification persistence via Supabase
public final class SupabaseClarificationRepository: ClarificationTrackerPort, @unchecked Sendable {
    private let databaseClient: SupabaseDatabasePort
    private let mapper: IntelligenceMapper
    private let tableName = "clarification_traces"

    public init(databaseClient: SupabaseDatabasePort) {
        self.databaseClient = databaseClient
        self.mapper = IntelligenceMapper()
    }

    public func recordClarification(_ trace: ClarificationTrace) async throws {
        let record = mapper.toRecord(trace)
        _ = try await databaseClient.insert(table: tableName, values: record)
    }

    public func updatePrdId(questionId: UUID, prdId: UUID) async throws {
        let filter = QueryFilter(
            field: "question_id",
            operation: .equals,
            value: questionId.uuidString.lowercased()
        )
        let update = ["prd_id": prdId.uuidString.lowercased()]
        _ = try await databaseClient.update(table: tableName, values: update, matching: filter)
    }

    public func updateAnswerByQuestionId(
        questionId: UUID,
        userAnswer: String,
        answerTimestamp: Date
    ) async throws {
        let filter = QueryFilter(
            field: "question_id",
            operation: .equals,
            value: questionId.uuidString.lowercased()
        )

        let update = AnswerByQuestionIdDTO(
            userAnswer: userAnswer,
            answerTimestamp: answerTimestamp
        )

        _ = try await databaseClient.update(table: tableName, values: update, matching: filter)
    }

    public func updateWithAnswer(
        traceId: UUID,
        userAnswer: String,
        impactOnPrd: String?,
        influencedSections: [UUID]
    ) async throws {
        let filter = QueryFilter(
            field: "id",
            operation: .equals,
            value: traceId.uuidString.lowercased()
        )

        let update = AnswerUpdateDTO(
            userAnswer: userAnswer,
            answerTimestamp: Date(),
            impactOnPrd: impactOnPrd,
            influencedSections: influencedSections.map { $0.uuidString.lowercased() }
        )

        _ = try await databaseClient.update(table: tableName, values: update, matching: filter)
    }

    public func updateEffectiveness(
        traceId: UUID,
        wasHelpful: Bool,
        improvedQuality: Bool,
        shouldAskAgainForSimilar: Bool
    ) async throws {
        let filter = QueryFilter(
            field: "id",
            operation: .equals,
            value: traceId.uuidString.lowercased()
        )

        let update = EffectivenessUpdateDTO(
            wasHelpful: wasHelpful,
            improvedQuality: improvedQuality,
            shouldAskAgainForSimilar: shouldAskAgainForSimilar
        )

        _ = try await databaseClient.update(table: tableName, values: update, matching: filter)
    }

    public func findByPrdId(_ prdId: UUID) async throws -> [ClarificationTrace] {
        let filter = QueryFilter(
            field: "prd_id",
            operation: .equals,
            value: prdId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseClarificationRecord].self, from: data)
        return records.compactMap { mapToDomain($0) }
    }

    public func findAnsweredByQuestionIds(_ questionIds: [UUID]) async throws -> [ClarificationTrace] {
        guard !questionIds.isEmpty else { return [] }

        // Query each questionId and filter for answered ones
        var results: [ClarificationTrace] = []
        for questionId in questionIds {
            let filter = QueryFilter(
                field: "question_id",
                operation: .equals,
                value: questionId.uuidString.lowercased()
            )
            let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
            let records = try createDecoder().decode([SupabaseClarificationRecord].self, from: data)
            let traces = records.compactMap { mapToDomain($0) }
            // Only include answered ones
            results.append(contentsOf: traces.filter { $0.userAnswer != nil })
        }
        return results
    }

    public func findHelpfulByCategory(
        _ category: ClarificationCategory,
        limit: Int
    ) async throws -> [ClarificationTrace] {
        let filter = QueryFilter(
            field: "question_category",
            operation: .equals,
            value: category.rawValue
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseClarificationRecord].self, from: data)
        return Array(records.compactMap { mapToDomain($0) }.filter { $0.wasHelpful == true }.prefix(limit))
    }

    private func mapToDomain(_ record: SupabaseClarificationRecord) -> ClarificationTrace? {
        guard let id = UUID(uuidString: record.id),
              let questionId = UUID(uuidString: record.questionId) else {
            return nil
        }

        return ClarificationTrace(
            id: id,
            prdId: record.prdId.flatMap { UUID(uuidString: $0) },
            questionId: questionId,
            questionText: record.questionText,
            questionCategory: record.questionCategory.flatMap { ClarificationCategory(rawValue: $0) },
            reasoningForAsking: record.reasoningForAsking,
            gapAddressed: record.gapAddressed,
            userAnswer: record.userAnswer,
            answerTimestamp: record.answerTimestamp,
            impactOnPrd: record.impactOnPrd,
            influencedSections: record.influencedSections?.compactMap { UUID(uuidString: $0) } ?? [],
            wasHelpful: record.wasHelpful,
            improvedQuality: record.improvedQuality,
            shouldAskAgainForSimilar: record.shouldAskAgainForSimilar,
            coherenceScore: record.coherenceScore,
            valueAddScore: record.valueAddScore,
            wasAskedToUser: record.wasAskedToUser ?? true,
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
