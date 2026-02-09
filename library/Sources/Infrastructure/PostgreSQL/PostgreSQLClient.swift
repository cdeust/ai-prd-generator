import AIPRDSharedUtilities
import Foundation
import PostgresNIO

/// PostgreSQL client implementation using PostgresNIO
/// Single Responsibility: Direct PostgreSQL database access
/// Actor for thread-safe connection management
public actor PostgreSQLClient: PostgreSQLDatabasePort {
    private var connection: PostgresConnection?
    private var eventLoopGroup: MultiThreadedEventLoopGroup?
    private var isInTransaction: Bool = false

    public init() {}

    // MARK: - Connection Management

    public func connect(connectionString: String) async throws {
        guard connection == nil else { return }

        guard let config = try? parseConnectionString(connectionString) else {
            throw PostgreSQLError.invalidConnectionString
        }

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        eventLoopGroup = group

        do {
            let conn = try await PostgresConnection.connect(
                on: group.next(),
                configuration: config,
                id: 1,
                logger: .init(label: "PostgreSQL")
            )
            connection = conn
        } catch {
            try? await group.shutdownGracefully()
            throw PostgreSQLError.connectionFailed(error.localizedDescription)
        }
    }

    public func disconnect() async throws {
        if let conn = connection {
            try? await conn.close()
            connection = nil
        }

        if let group = eventLoopGroup {
            try await group.shutdownGracefully()
            eventLoopGroup = nil
        }
    }

    // MARK: - Raw Query Execution

    public func executeQuery(_ sql: String, parameters: [Any]) async throws -> [[String: Any]] {
        guard let conn = connection else {
            throw PostgreSQLError.notConnected
        }

        do {
            let binds = try buildBindings(from: parameters)
            let stream = try await conn.query(
                PostgresQuery(unsafeSQL: sql, binds: binds),
                logger: .init(label: "PostgreSQL")
            )

            var results: [[String: Any]] = []
            for try await row in stream {
                results.append(try convertRow(row))
            }
            return results
        } catch {
            throw PostgreSQLError.queryFailed(error.localizedDescription)
        }
    }

    // MARK: - RPC Operations

    public func callRPC(function: String, parameters: [String: Any]) async throws -> Data {
        let paramNames = parameters.keys.sorted()
        let placeholders = paramNames.enumerated()
            .map { "\($0.element) => $\($0.offset + 1)" }
            .joined(separator: ", ")

        let sql = "SELECT * FROM \(function)(\(placeholders));"

        let params = paramNames.compactMap { parameters[$0] }
        let rows = try await executeQuery(sql, parameters: params)

        return try JSONSerialization.data(withJSONObject: rows)
    }

    public func callRPC<T: Decodable>(
        function: String,
        parameters: [String: Any]
    ) async throws -> T {
        let data = try await callRPC(function: function, parameters: parameters)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Transaction Support

    public func beginTransaction() async throws {
        guard !isInTransaction else { return }
        _ = try await executeQuery("BEGIN;", parameters: [])
        isInTransaction = true
    }

    public func commit() async throws {
        guard isInTransaction else { return }
        _ = try await executeQuery("COMMIT;", parameters: [])
        isInTransaction = false
    }

    public func rollback() async throws {
        guard isInTransaction else { return }
        _ = try await executeQuery("ROLLBACK;", parameters: [])
        isInTransaction = false
    }

    // MARK: - Private Helpers

    private func parseConnectionString(_ connectionString: String) throws -> PostgresConnection.Configuration {
        // Parse postgresql://user:password@host:port/database
        guard let url = URL(string: connectionString) else {
            throw PostgreSQLError.invalidConnectionString
        }

        let host = url.host ?? "localhost"
        let port = url.port ?? 5432
        let user = url.user ?? "postgres"
        let password = url.password
        let database = url.path.replacingOccurrences(of: "/", with: "")

        return PostgresConnection.Configuration(
            host: host,
            port: port,
            username: user,
            password: password,
            database: database,
            tls: .disable
        )
    }

    private func buildBindings(from parameters: [Any]) throws -> PostgresBindings {
        var binds = PostgresBindings()
        for param in parameters {
            if let str = param as? String {
                binds.append(str)
            } else if let int = param as? Int {
                binds.append(int)
            } else if let int64 = param as? Int64 {
                binds.append(int64)
            } else if let double = param as? Double {
                binds.append(double)
            } else if let float = param as? Float {
                binds.append(float)
            } else if let bool = param as? Bool {
                binds.append(bool)
            } else if let uuid = param as? UUID {
                binds.append(uuid)
            } else if let data = param as? Data {
                try binds.append(data)
            } else if let floatArray = param as? [Float] {
                binds.append(floatArray)
            } else {
                binds.append(String(describing: param))
            }
        }
        return binds
    }

    private func convertRow(_ row: PostgresRow) throws -> [String: Any] {
        var dict: [String: Any] = [:]

        // Iterate over all cells in the row
        for cell in row {
            let columnName = cell.columnName

            if cell.bytes != nil {
                // Try to decode based on PostgreSQL data type
                // Use type-based decoding to handle all PostgreSQL types properly
                if let val = try? cell.decode(String.self) {
                    dict[columnName] = val
                } else if let val = try? cell.decode(Int.self) {
                    dict[columnName] = val
                } else if let val = try? cell.decode(Int64.self) {
                    dict[columnName] = val
                } else if let val = try? cell.decode(Int32.self) {
                    dict[columnName] = val
                } else if let val = try? cell.decode(Int16.self) {
                    dict[columnName] = val
                } else if let val = try? cell.decode(Double.self) {
                    dict[columnName] = val
                } else if let val = try? cell.decode(Float.self) {
                    dict[columnName] = val
                } else if let val = try? cell.decode(Bool.self) {
                    dict[columnName] = val
                } else if let val = try? cell.decode(UUID.self) {
                    dict[columnName] = val.uuidString
                } else if let val = try? cell.decode(Date.self) {
                    dict[columnName] = ISO8601DateFormatter().string(from: val)
                } else if let val = try? cell.decode(Data.self) {
                    dict[columnName] = val
                } else {
                    // For other types including arrays, try as String as fallback
                    if let val = try? cell.decode(String.self) {
                        dict[columnName] = val
                    } else {
                        dict[columnName] = nil
                    }
                }
            } else {
                dict[columnName] = nil
            }
        }

        return dict
    }
}
