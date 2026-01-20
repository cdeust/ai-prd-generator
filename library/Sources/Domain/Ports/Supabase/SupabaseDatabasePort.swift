import Foundation

/// Port for Supabase database operations
/// Domain defines interface, Infrastructure implements with Supabase SDK
public protocol SupabaseDatabasePort: Sendable {
    // MARK: - Query Operations

    /// Insert records into table
    func insert<T: Encodable>(table: String, values: T) async throws -> Data

    /// Insert or update records (upsert) based on conflict columns
    func upsert<T: Encodable>(table: String, values: T, onConflict: [String]) async throws -> Data

    /// Insert multiple records
    func insertBatch<T: Encodable>(table: String, values: [T]) async throws -> Data

    /// Update records in table
    func update<T: Encodable>(table: String, values: T, matching: QueryFilter) async throws -> Data

    /// Delete records from table
    func delete(from table: String, matching: QueryFilter) async throws

    /// Select records from table
    func select(from table: String, columns: [String]?, filter: QueryFilter?) async throws -> Data

    /// Count records in table
    func count(from table: String, filter: QueryFilter?) async throws -> Int

    // MARK: - RPC Operations

    /// Call Supabase RPC function (for pgvector search)
    func callRPC(function: String, parameters: [String: Any]) async throws -> Data

    /// Call RPC function with typed response
    func callRPC<T: Decodable>(function: String, parameters: [String: Any], responseType: T.Type) async throws -> T
}
