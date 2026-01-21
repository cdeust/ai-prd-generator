import Foundation

/// Port for PostgreSQL database operations
/// Domain defines interface, Infrastructure implements with direct SQL
/// Database port for local PostgreSQL (standalone skill)
/// Reuses QueryFilter from domain (database-agnostic filter concept)
public protocol PostgreSQLDatabasePort: Sendable {
    // MARK: - Connection Management

    /// Connect to PostgreSQL database
    func connect(connectionString: String) async throws

    /// Disconnect from database
    func disconnect() async throws

    // MARK: - Raw Query Execution

    /// Execute raw SQL query with parameters
    func executeQuery(_ sql: String, parameters: [Any]) async throws -> [[String: Any]]

    // MARK: - Query Operations

    /// Insert record into table
    func insert<T: Encodable>(table: String, values: T) async throws -> Data

    /// Insert record from dictionary
    func insert(table: String, values: [String: Any]) async throws -> Data

    /// Insert or update records (upsert) based on conflict columns
    func upsert<T: Encodable>(
        table: String,
        values: T,
        onConflict: [String]
    ) async throws -> Data

    /// Insert or update record from dictionary
    func upsert(
        table: String,
        values: [String: Any],
        onConflict: [String]
    ) async throws -> Data

    /// Insert multiple records
    func insertBatch<T: Encodable>(table: String, values: [T]) async throws -> Data

    /// Insert multiple records from dictionaries
    func insertBatch(table: String, values: [[String: Any]]) async throws -> Data

    /// Update records in table
    func update<T: Encodable>(
        table: String,
        values: T,
        whereClause: String,
        parameters: [Any]
    ) async throws -> Data

    /// Update records from dictionary
    func update(
        table: String,
        values: [String: Any],
        whereClause: String,
        parameters: [Any]
    ) async throws -> Data

    /// Delete records from table
    func delete(from table: String, whereClause: String, parameters: [Any]) async throws

    /// Select records from table
    func select(
        from table: String,
        columns: [String]?,
        whereClause: String?,
        parameters: [Any]?
    ) async throws -> Data

    /// Count records in table
    func count(from table: String, whereClause: String?, parameters: [Any]?) async throws -> Int

    // MARK: - RPC Operations

    /// Call PostgreSQL function (for pgvector search)
    func callRPC(function: String, parameters: [String: Any]) async throws -> Data

    /// Call RPC function with typed response
    func callRPC<T: Decodable>(
        function: String,
        parameters: [String: Any],
        responseType: T.Type
    ) async throws -> T

    // MARK: - Transaction Support

    /// Begin transaction
    func beginTransaction() async throws

    /// Commit transaction
    func commit() async throws

    /// Rollback transaction
    func rollback() async throws
}
