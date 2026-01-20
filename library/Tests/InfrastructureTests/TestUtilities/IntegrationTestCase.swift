import XCTest
@testable import InfrastructureCore
@testable import Domain

/// Base class for integration tests with REAL database
/// Provides database lifecycle management (setup, cleanup, teardown)
///
/// Usage:
/// ```swift
/// final class MyRepositoryIntegrationSpec: IntegrationTestCase {
///     func testSaveAndRetrieve() async throws {
///         // Test with REAL database via self.supabaseClient
///         let repository = SupabasePRDRepository(client: supabaseClient)
///         // ...
///     }
/// }
/// ```
open class IntegrationTestCase: XCTestCase {
    public var testDB: TestDatabaseManager!
    public var supabaseClient: SupabaseClient!

    /// Set up test database before each test
    /// Verifies connectivity and schema
    open override func setUp() async throws {
        try await super.setUp()

        // Create test database manager
        testDB = TestDatabaseManager(config: .fromEnvironment())

        // Wait for database to be ready (important for CI/CD)
        do {
            try await testDB.waitUntilReady(timeout: 30.0)
        } catch {
            XCTFail("Test database not ready: \(error). Did you run `docker-compose up`?")
            throw error
        }

        // Verify connectivity
        let healthy = await testDB.isHealthy()
        XCTAssertTrue(healthy, "Test database not accessible")

        // Create Supabase client pointing to local test database
        let config = TestDatabaseManager.TestDatabaseConfig.fromEnvironment()
        supabaseClient = SupabaseClient(
            url: "http://\(config.host):\(config.port)",
            apiKey: config.apiKey
        )
    }

    /// Clean database after each test
    /// Ensures test isolation
    open override func tearDown() async throws {
        // Clean all test data
        do {
            try await testDB?.cleanDatabase()
        } catch {
            print("⚠️  Failed to clean test database: \(error)")
            // Don't fail the test if cleanup fails
        }

        try await super.tearDown()
    }
}
