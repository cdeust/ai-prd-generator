import Foundation
import Domain

/// Supabase implementation of PRD Repository
/// Single Responsibility: PRD persistence via Supabase
/// Following naming: Supabase{Domain}Repository
public final class SupabasePRDRepository: PRDRepositoryPort {
    private let databaseClient: SupabaseDatabasePort
    private let mapper: SupabasePRDDocumentMapper
    private let sectionRepository: SupabasePRDSectionRepository
    private let tableName: String

    public init(
        databaseClient: SupabaseDatabasePort,
        tableName: String = "prd_documents",
        sectionsTableName: String = "prd_sections"
    ) {
        self.databaseClient = databaseClient
        self.mapper = SupabasePRDDocumentMapper()
        self.sectionRepository = SupabasePRDSectionRepository(
            databaseClient: databaseClient,
            tableName: sectionsTableName
        )
        self.tableName = tableName
    }

    public func save(_ document: PRDDocument) async throws -> PRDDocument {
        let documentIdLower = document.id.uuidString.lowercased()
        print("📝 [PRDRepo] Saving new document: \(documentIdLower)")

        let record = mapper.toRecord(document)
        print("📝 [PRDRepo] Record ID: \(record.id), userId: \(record.userId ?? "nil")")

        // Insert document and verify it was created
        let responseData = try await databaseClient.insert(table: tableName, values: record)
        let responseStr = String(data: responseData, encoding: .utf8) ?? "non-utf8"
        print("📝 [PRDRepo] Insert response: \(responseStr.prefix(500))")

        // Verify the document was actually inserted by checking the response
        // Supabase returns empty array `[]` if insert fails silently (RLS, etc)
        // It also returns the inserted record(s) on success
        try verifyInsertResponse(responseData, documentId: document.id)
        print("📝 [PRDRepo] Insert response verified")

        // Double-check: Verify document exists before inserting sections
        // This catches any edge cases where insert appears successful but document isn't visible
        let verifyDoc = try await findById(document.id)
        guard verifyDoc != nil else {
            throw RepositoryError.saveFailed(
                "Document insert appeared successful but document not found in database. ID: \(document.id)"
            )
        }
        print("📝 [PRDRepo] Document verified in database")

        // Delete any existing sections (in case of re-save) then save new ones
        try await sectionRepository.deleteSections(documentId: document.id)
        try await sectionRepository.saveSections(document.sections, documentId: document.id)
        print("📝 [PRDRepo] Initial save complete (sections: \(document.sections.count))")

        // Return the document as-is since we know what was inserted
        return document
    }

    /// Verify that insert actually succeeded by checking response data
    private func verifyInsertResponse(_ data: Data, documentId: UUID) throws {
        // Try to decode as array of any JSON objects
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            // Response isn't a valid JSON array - log and check if it's an error
            let responseString = String(data: data, encoding: .utf8) ?? "non-utf8"
            throw RepositoryError.saveFailed(
                "Document insert returned invalid response: \(responseString.prefix(200))"
            )
        }

        // Empty array means RLS blocked the insert or it failed silently
        if jsonArray.isEmpty {
            throw RepositoryError.saveFailed(
                "Document insert failed - returned empty response. Check: 1) user_id exists in users table, 2) RLS policies allow insert"
            )
        }

        // Verify the returned document has the expected ID (case-insensitive comparison)
        if let firstDoc = jsonArray.first,
           let returnedId = firstDoc["id"] as? String,
           returnedId.lowercased() != documentId.uuidString.lowercased() {
            throw RepositoryError.saveFailed(
                "Document insert returned unexpected ID: \(returnedId) vs expected \(documentId)"
            )
        }
    }

    public func findById(_ id: UUID) async throws -> PRDDocument? {
        let filter = QueryFilter(
            field: "id",
            operation: .equals,
            value: id.uuidString.lowercased()
        )
        let data = try await databaseClient.select(
            from: tableName,
            columns: nil,
            filter: filter
        )

        let records = try decodeRecordArray(data)
        guard let record = records.first else { return nil }

        let sections = try await sectionRepository.loadSections(documentId: id)
        return mapper.toDomain(record, sections: sections)
    }

    public func findAll(limit: Int, offset: Int) async throws -> [PRDDocument] {
        let data = try await databaseClient.select(
            from: tableName,
            columns: nil,
            filter: nil
        )

        let records = try decodeRecordArray(data)
        var documents: [PRDDocument] = []
        for record in records {
            guard let recordId = UUID(uuidString: record.id) else { continue }
            let sections = try await sectionRepository.loadSections(documentId: recordId)
            documents.append(mapper.toDomain(record, sections: sections))
        }
        return documents
    }

    public func update(_ document: PRDDocument) async throws -> PRDDocument {
        let documentIdLower = document.id.uuidString.lowercased()
        print("📝 [PRDRepo] Updating document: \(documentIdLower)")

        // First verify the document exists
        let existingDoc = try await findById(document.id)
        guard existingDoc != nil else {
            throw RepositoryError.saveFailed(
                "Cannot update - document not found in database. ID: \(documentIdLower)"
            )
        }
        print("📝 [PRDRepo] Document exists, proceeding with update")

        let record = mapper.toRecord(document)
        let filter = QueryFilter(
            field: "id",
            operation: .equals,
            value: documentIdLower
        )
        // Update document - we don't decode response due to potential RLS issues
        _ = try await databaseClient.update(
            table: tableName,
            values: record,
            matching: filter
        )
        print("📝 [PRDRepo] Document updated, now upserting \(document.sections.count) sections")

        // Upsert sections (update existing or insert new - preserves strategy values)
        try await sectionRepository.saveSections(document.sections, documentId: document.id)
        print("📝 [PRDRepo] Sections upserted successfully")

        // Return the document as-is since we know what was updated
        return document
    }

    public func delete(_ id: UUID) async throws {
        let filter = QueryFilter(
            field: "id",
            operation: .equals,
            value: id.uuidString.lowercased()
        )
        try await databaseClient.delete(from: tableName, matching: filter)
    }

    public func search(query: String, limit: Int) async throws -> [PRDDocument] {
        let filter = QueryFilter(
            field: "search_text",
            operation: .ilike,
            value: "%\(query)%"
        )
        let data = try await databaseClient.select(
            from: tableName,
            columns: nil,
            filter: filter
        )

        let records = try decodeRecordArray(data)
        var documents: [PRDDocument] = []
        for record in records {
            guard let recordId = UUID(uuidString: record.id) else { continue }
            let sections = try await sectionRepository.loadSections(documentId: recordId)
            documents.append(mapper.toDomain(record, sections: sections))
        }
        return documents
    }

    // MARK: - Private Decoding Methods

    private func decodeRecordArray(_ data: Data) throws -> [SupabasePRDDocumentRecord] {
        let decoder = createDecoder()
        return try decoder.decode([SupabasePRDDocumentRecord].self, from: data)
    }

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
