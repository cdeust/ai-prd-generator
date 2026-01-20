import Foundation
import Domain

/// Supabase implementation of SessionRepositoryPort
/// Persists sessions to Supabase sessions table
public final class SupabaseSessionRepository: SessionRepositoryPort, Sendable {
    private let client: SupabaseDatabasePort
    private let mapper: SupabaseSessionMapper
    private let tableName = "sessions"

    public init(client: SupabaseDatabasePort) {
        self.client = client
        self.mapper = SupabaseSessionMapper()
    }

    public func create(_ session: Session) async throws -> Session {
        let record = mapper.toRecord(session)
        let data = try await client.insert(table: tableName, values: record)
        let saved = try decodeRecord(data)
        return mapper.toDomain(saved)
    }

    public func findById(_ id: UUID) async throws -> Session? {
        let filter = QueryFilter(field: "id", operation: .equals, value: id.uuidString)
        let data = try await client.select(from: tableName, columns: nil, filter: filter)
        let records = try decodeRecordArray(data)
        return records.first.map { mapper.toDomain($0) }
    }

    public func findAll() async throws -> [Session] {
        let data = try await client.select(from: tableName, columns: nil, filter: nil)
        let records = try decodeRecordArray(data)
        return records.map { mapper.toDomain($0) }
    }

    public func update(_ session: Session) async throws -> Session {
        let record = mapper.toRecord(session)
        let filter = QueryFilter(field: "id", operation: .equals, value: session.id.uuidString)
        let data = try await client.update(table: tableName, values: record, matching: filter)
        let updated = try decodeRecord(data)
        return mapper.toDomain(updated)
    }

    public func delete(_ id: UUID) async throws {
        let filter = QueryFilter(field: "id", operation: .equals, value: id.uuidString)
        try await client.delete(from: tableName, matching: filter)
    }

    public func findActive() async throws -> [Session] {
        let filter = QueryFilter(field: "is_active", operation: .equals, value: "true")
        let data = try await client.select(from: tableName, columns: nil, filter: filter)
        let records = try decodeRecordArray(data)
        return records.map { mapper.toDomain($0) }
    }

    public func addMessage(_ message: ChatMessage, to sessionId: UUID) async throws -> ChatMessage {
        guard var session = try await findById(sessionId) else {
            throw RepositoryError.invalidQuery("Session not found: \(sessionId)")
        }
        session.addMessage(message)
        _ = try await update(session)
        return message
    }

    public func getMessages(for sessionId: UUID, limit: Int) async throws -> [ChatMessage] {
        guard let session = try await findById(sessionId) else {
            return []
        }
        return Array(session.messages.suffix(limit))
    }

    private func decodeRecord(_ data: Data) throws -> SupabaseSessionRecord {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(SupabaseSessionRecord.self, from: data)
    }

    private func decodeRecordArray(_ data: Data) throws -> [SupabaseSessionRecord] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([SupabaseSessionRecord].self, from: data)
    }
}
