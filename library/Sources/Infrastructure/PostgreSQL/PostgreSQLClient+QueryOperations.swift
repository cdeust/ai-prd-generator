import AIPRDSharedUtilities
import Foundation

/// Extension for CRUD query operations
/// Single Responsibility: Database query execution (insert, update, delete, select)
extension PostgreSQLClient {
    // MARK: - Query Operations

    public func insert<T: Encodable>(table: String, values: T) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(values)

        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PostgreSQLError.parameterEncodingFailed("Failed to convert to dictionary")
        }

        return try await insert(table: table, values: dict)
    }

    public func insert(table: String, values: [String: Any]) async throws -> Data {
        let sortedKeys = values.keys.sorted()
        let columns = sortedKeys.joined(separator: ", ")
        let placeholders = (1...values.count).map { "$\($0)" }.joined(separator: ", ")
        let sql = "INSERT INTO \(table) (\(columns)) VALUES (\(placeholders)) RETURNING *;"

        let params = sortedKeys.compactMap { values[$0] }
        let rows = try await executeQuery(sql, parameters: params)

        return try JSONSerialization.data(withJSONObject: rows)
    }

    public func upsert<T: Encodable>(
        table: String,
        values: T,
        onConflict: [String]
    ) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(values)

        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PostgreSQLError.parameterEncodingFailed("Failed to convert to dictionary")
        }

        return try await upsert(table: table, values: dict, onConflict: onConflict)
    }

    public func upsert(
        table: String,
        values: [String: Any],
        onConflict: [String]
    ) async throws -> Data {
        let columns = values.keys.sorted()
        let columnsList = columns.joined(separator: ", ")
        let placeholders = (1...values.count).map { "$\($0)" }.joined(separator: ", ")

        let updateSet = columns
            .filter { !onConflict.contains($0) }
            .map { "\($0) = EXCLUDED.\($0)" }
            .joined(separator: ", ")

        let conflictColumns = onConflict.joined(separator: ", ")

        let sql = """
        INSERT INTO \(table) (\(columnsList))
        VALUES (\(placeholders))
        ON CONFLICT (\(conflictColumns))
        DO UPDATE SET \(updateSet)
        RETURNING *;
        """

        let params = columns.compactMap { values[$0] }
        let rows = try await executeQuery(sql, parameters: params)

        return try JSONSerialization.data(withJSONObject: rows)
    }

    public func insertBatch<T: Encodable>(table: String, values: [T]) async throws -> Data {
        guard !values.isEmpty else {
            return try JSONSerialization.data(withJSONObject: [])
        }

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        var dicts: [[String: Any]] = []
        for value in values {
            let data = try encoder.encode(value)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw PostgreSQLError.parameterEncodingFailed("Failed to convert to dictionary")
            }
            dicts.append(dict)
        }

        return try await insertBatch(table: table, values: dicts)
    }

    public func insertBatch(table: String, values: [[String: Any]]) async throws -> Data {
        guard !values.isEmpty else {
            return try JSONSerialization.data(withJSONObject: [])
        }

        var allRows: [[String: Any]] = []

        for dict in values {
            let columns = dict.keys.sorted().joined(separator: ", ")
            let placeholders = (1...dict.count).map { "$\($0)" }.joined(separator: ", ")
            let sql = "INSERT INTO \(table) (\(columns)) VALUES (\(placeholders)) RETURNING *;"

            let params = dict.keys.sorted().compactMap { dict[$0] }
            let rows = try await executeQuery(sql, parameters: params)
            allRows.append(contentsOf: rows)
        }

        return try JSONSerialization.data(withJSONObject: allRows)
    }

    public func update<T: Encodable>(
        table: String,
        values: T,
        whereClause: String,
        parameters: [Any]
    ) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(values)

        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PostgreSQLError.parameterEncodingFailed("Failed to convert to dictionary")
        }

        return try await update(table: table, values: dict, whereClause: whereClause, parameters: parameters)
    }

    public func update(
        table: String,
        values: [String: Any],
        whereClause: String,
        parameters: [Any]
    ) async throws -> Data {
        let columns = values.keys.sorted()
        let setClause = columns.enumerated()
            .map { "\($0.element) = $\($0.offset + 1)" }
            .joined(separator: ", ")

        let sql = "UPDATE \(table) SET \(setClause) WHERE \(whereClause) RETURNING *;"

        let allParams = columns.compactMap { values[$0] } + parameters
        let rows = try await executeQuery(sql, parameters: allParams)

        return try JSONSerialization.data(withJSONObject: rows)
    }

    public func delete(from table: String, whereClause: String, parameters: [Any]) async throws {
        let sql = "DELETE FROM \(table) WHERE \(whereClause);"
        _ = try await executeQuery(sql, parameters: parameters)
    }

    public func select(
        from table: String,
        columns: [String]?,
        whereClause: String?,
        parameters: [Any]?
    ) async throws -> Data {
        let columnList = columns?.joined(separator: ", ") ?? "*"
        var sql = "SELECT \(columnList) FROM \(table)"

        if let whereClause = whereClause {
            sql += " WHERE \(whereClause)"
        }

        sql += ";"

        let rows = try await executeQuery(sql, parameters: parameters ?? [])
        return try JSONSerialization.data(withJSONObject: rows)
    }

    public func count(from table: String, whereClause: String?, parameters: [Any]?) async throws -> Int {
        var sql = "SELECT COUNT(*) as count FROM \(table)"

        if let whereClause = whereClause {
            sql += " WHERE \(whereClause)"
        }

        sql += ";"

        let rows = try await executeQuery(sql, parameters: parameters ?? [])
        guard let first = rows.first,
              let count = first["count"] as? Int else {
            return 0
        }

        return count
    }
}
