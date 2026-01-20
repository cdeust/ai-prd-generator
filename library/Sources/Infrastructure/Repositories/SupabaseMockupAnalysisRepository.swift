import Foundation
import Domain

/// Supabase implementation of mockup analysis tracking
/// Single Responsibility: Mockup analysis persistence via Supabase
public final class SupabaseMockupAnalysisRepository: MockupAnalysisTrackerPort, @unchecked Sendable {
    private let databaseClient: SupabaseDatabasePort
    private let mapper: IntelligenceMapper
    private let tableName = "mockup_analysis_traces"

    public init(databaseClient: SupabaseDatabasePort) {
        self.databaseClient = databaseClient
        self.mapper = IntelligenceMapper()
    }

    public func recordAnalysis(_ trace: MockupAnalysisTrace) async throws {
        let record = mapper.toRecord(trace)
        _ = try await databaseClient.insert(table: tableName, values: record)
    }

    public func updatePrdId(mockupId: UUID, prdId: UUID) async throws {
        let filter = QueryFilter(
            field: "mockup_id",
            operation: .equals,
            value: mockupId.uuidString.lowercased()
        )
        let update = ["prd_id": prdId.uuidString.lowercased()]
        _ = try await databaseClient.update(table: tableName, values: update, matching: filter)
    }

    public func findByPrdId(_ prdId: UUID) async throws -> [MockupAnalysisTrace] {
        let filter = QueryFilter(
            field: "prd_id",
            operation: .equals,
            value: prdId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseMockupAnalysisRecord].self, from: data)
        return records.compactMap { mapToDomain($0) }
    }

    public func findByMockupId(_ mockupId: UUID) async throws -> [MockupAnalysisTrace] {
        let filter = QueryFilter(
            field: "mockup_id",
            operation: .equals,
            value: mockupId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(from: tableName, columns: nil, filter: filter)
        let records = try createDecoder().decode([SupabaseMockupAnalysisRecord].self, from: data)
        return records.compactMap { mapToDomain($0) }
    }

    private func mapToDomain(_ record: SupabaseMockupAnalysisRecord) -> MockupAnalysisTrace? {
        guard let id = UUID(uuidString: record.id),
              let mockupId = UUID(uuidString: record.mockupId) else {
            return nil
        }

        return MockupAnalysisTrace(
            id: id,
            mockupId: mockupId,
            prdId: record.prdId.flatMap { UUID(uuidString: $0) },
            llmInteractionId: record.llmInteractionId.flatMap { UUID(uuidString: $0) },
            analysisPrompt: record.analysisPrompt,
            llmResponse: record.llmResponse,
            detectedPatterns: [],
            uiComponents: record.uiComponents ?? [],
            colorScheme: nil,
            layoutType: record.layoutType,
            uncertainties: record.uncertainties ?? [],
            clarificationQuestions: record.clarificationQuestions ?? [],
            influencedSections: record.influencedSections?.compactMap { UUID(uuidString: $0) } ?? [],
            confidenceScore: record.confidenceScore,
            visionModel: record.visionModel,
            visionProvider: record.visionProvider,
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
