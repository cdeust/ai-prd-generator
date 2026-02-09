import AIPRDSharedUtilities
import Foundation

/// Manages local test database lifecycle
/// Handles setup, cleanup, and teardown for integration tests
public actor TestDatabaseManager {
    private let baseURL: URL
    private let apiKey: String

    public struct TestDatabaseConfig {
        let host: String
        let port: Int
        let apiKey: String

        public static let `default` = TestDatabaseConfig(
            host: "localhost",
            port: 54321,  // PostgREST port from docker-compose
            apiKey: "test-api-key"
        )

        public static func fromEnvironment() -> TestDatabaseConfig {
            TestDatabaseConfig(
                host: ProcessInfo.processInfo.environment["TEST_DB_HOST"] ?? "localhost",
                port: Int(ProcessInfo.processInfo.environment["TEST_DB_PORT"] ?? "54321") ?? 54321,
                apiKey: ProcessInfo.processInfo.environment["TEST_DB_API_KEY"] ?? "test-api-key"
            )
        }
    }

    public init(config: TestDatabaseConfig = .default) {
        self.baseURL = URL(string: "http://\(config.host):\(config.port)")!
        self.apiKey = config.apiKey
    }

    /// Check if test database is accessible
    public func isHealthy() async -> Bool {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        } catch {
            print("❌ Test database health check failed: \(error)")
            return false
        }
    }

    /// Clean all test data from database
    /// Call this after each test to ensure isolation
    public func cleanDatabase() async throws {
        // Call the truncate_all_tables() function defined in init.sql
        let url = baseURL.appendingPathComponent("rpc/truncate_all_tables")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TestDatabaseError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw TestDatabaseError.cleanupFailed(statusCode: httpResponse.statusCode)
            }
        } catch {
            throw TestDatabaseError.cleanupError(underlying: error)
        }
    }

    /// Verify database schema exists and is valid
    public func verifySchema() async throws {
        // Check if key tables exist
        let tables = [
            "prd_documents",
            "codebases",
            "code_files",
            "code_chunks",
            "code_embeddings"
        ]

        for table in tables {
            let url = baseURL.appendingPathComponent(table)
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.setValue(apiKey, forHTTPHeaderField: "apikey")

            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TestDatabaseError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw TestDatabaseError.schemaMissing(table: table)
            }
        }
    }

    /// Wait for database to be ready (useful for CI/CD)
    public func waitUntilReady(timeout: TimeInterval = 30.0) async throws {
        let start = Date()

        while Date().timeIntervalSince(start) < timeout {
            if await isHealthy() {
                try await verifySchema()
                return
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        }

        throw TestDatabaseError.timeout
    }
}

// MARK: - Errors

public enum TestDatabaseError: Error, CustomStringConvertible {
    case invalidResponse
    case cleanupFailed(statusCode: Int)
    case cleanupError(underlying: Error)
    case schemaMissing(table: String)
    case timeout

    public var description: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from test database"
        case .cleanupFailed(let statusCode):
            return "Database cleanup failed with status code: \(statusCode)"
        case .cleanupError(let error):
            return "Database cleanup error: \(error)"
        case .schemaMissing(let table):
            return "Database schema missing table: \(table)"
        case .timeout:
            return "Test database did not become ready within timeout"
        }
    }
}
