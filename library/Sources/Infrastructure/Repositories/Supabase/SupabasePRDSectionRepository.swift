import Foundation
import Domain

/// Repository for PRD section operations
/// Single Responsibility: Section persistence via Supabase
final class SupabasePRDSectionRepository {
    private let databaseClient: SupabaseDatabasePort
    private let tableName: String
    private let mapper = SupabasePRDSectionMapper()

    init(databaseClient: SupabaseDatabasePort, tableName: String = "prd_sections") {
        self.databaseClient = databaseClient
        self.tableName = tableName
    }

    func saveSections(_ sections: [PRDSection], documentId: UUID) async throws {
        let docIdLower = documentId.uuidString.lowercased()
        print("📝 [PRDRepo] Saving \(sections.count) sections for document: \(docIdLower)")

        for (index, section) in sections.enumerated() {
            let record = mapper.sectionToRecord(section, documentId: documentId, orderIndex: index)
            print("📝 [PRDRepo] Upserting section \(index + 1)/\(sections.count): id=\(record.id), strategy=\(record.thinkingStrategy ?? "nil")")
            let responseData = try await databaseClient.upsert(table: tableName, values: record, onConflict: ["id"])
            let responseStr = String(data: responseData, encoding: .utf8) ?? "non-utf8"
            print("📝 [PRDRepo] Section upsert response: \(responseStr.prefix(200))")
        }
    }

    func loadSections(documentId: UUID) async throws -> [PRDSection] {
        let filter = QueryFilter(
            field: "prd_document_id",
            operation: .equals,
            value: documentId.uuidString.lowercased()
        )
        let data = try await databaseClient.select(
            from: tableName,
            columns: nil,
            filter: filter
        )

        let records = try decodeSectionArray(data)
        return records
            .sorted { ($0.orderIndex ?? 0) < ($1.orderIndex ?? 0) }
            .map { mapper.sectionToDomain($0) }
    }

    func deleteSections(documentId: UUID) async throws {
        let filter = QueryFilter(
            field: "prd_document_id",
            operation: .equals,
            value: documentId.uuidString.lowercased()
        )
        try await databaseClient.delete(from: tableName, matching: filter)
    }

    private func decodeSectionArray(_ data: Data) throws -> [SupabasePRDSectionRecord] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([SupabasePRDSectionRecord].self, from: data)
    }
}
