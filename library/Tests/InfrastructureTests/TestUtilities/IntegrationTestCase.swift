import AIPRDSharedUtilities
import XCTest
@testable import InfrastructureCore
@testable import Domain

/// Base class for integration tests with REAL database
/// Provides database lifecycle management (setup, cleanup, teardown)
///
/// NOTE: This class is currently disabled as it references obsolete Supabase classes.
/// The project has migrated to PostgreSQL. This needs to be updated or replaced.
open class IntegrationTestCase: XCTestCase {
    // Stubbed - needs migration to PostgreSQL
}
