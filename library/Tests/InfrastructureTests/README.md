# Infrastructure Tests

> Integration tests for adapters, repositories, and external service implementations

## Overview

Infrastructure tests validate **REAL implementations**, not mocks:
- **Real database operations** (PostgreSQL via PostgREST)
- **Real HTTP requests** (with mock responses)
- **Real file system operations** (in temp directories)
- **Real vector search** (pgvector)

**Mocks are NOT sufficient** - They test mock logic, not implementation correctness.

## Test Types

### Integration Tests (Real Database)

**Purpose:** Test real database operations
**Naming:** `{Component}IntegrationSpec.swift`
**Prerequisites:** Local test database running
**Execution Time:** 100-500ms per test

**Example:**
```swift
final class SupabasePRDRepositoryIntegrationSpec: IntegrationTestCase {
    func testSave_insertsDocumentIntoRealDatabase() async throws {
        // Given: REAL repository with REAL database
        let repository = SupabasePRDRepository(client: supabaseClient)

        let document = PRDDocument(...)

        // When: Save to REAL database
        let saved = try await repository.save(document)

        // Then: Document exists in REAL database
        XCTAssertNotNil(saved.id)

        // Verify by querying REAL database
        let found = try await repository.findById(saved.id)
        XCTAssertNotNil(found)
    }
}
```

### Contract Tests (Adapter Behavior)

**Purpose:** Verify adapters implement port contracts correctly
**Naming:** `{Adapter}ContractSpec.swift`
**Prerequisites:** Mock external services only
**Execution Time:** <50ms per test

**Example:**
```swift
final class AnthropicProviderContractSpec: XCTestCase {
    func testGenerateText_implementsAIProviderPort() async throws {
        // Test that adapter correctly implements port contract
        let provider = AnthropicProvider(...)

        // Verify contract requirements
        let result = try await provider.generateText(...)
        XCTAssertNotNil(result)
    }
}
```

## Running Tests

### 1. Start Test Database

```bash
cd docker/test-db
docker-compose up -d

# Wait for healthy
docker-compose ps
```

### 2. Run Integration Tests

```bash
cd library

# All integration tests
swift test --filter "IntegrationSpec"

# Specific repository
swift test --filter "SupabasePRDRepositoryIntegrationSpec"

# All infrastructure tests
swift test --filter "InfrastructureTests"
```

### 3. Stop Test Database

```bash
cd docker/test-db
docker-compose down
```

## Test Structure

```
Tests/InfrastructureTests/
├── README.md                          # This file
├── TestUtilities/
│   ├── IntegrationTestCase.swift      # Base class for DB tests
│   └── TestDatabaseManager.swift      # DB lifecycle management
│
├── Repositories/                      # Repository integration tests
│   ├── SupabasePRDRepositoryIntegrationSpec.swift
│   ├── SupabaseCodebaseRepositoryIntegrationSpec.swift
│   └── SupabasePRDTemplateRepositoryIntegrationSpec.swift
│
├── AIProviders/                       # AI provider contract tests
│   ├── AnthropicProviderContractSpec.swift
│   ├── OpenAIProviderContractSpec.swift
│   └── GeminiProviderContractSpec.swift
│
├── VectorSearch/                      # Vector search tests
│   └── SupabaseVectorSearchIntegrationSpec.swift
│
└── Chunking/                          # Code chunking tests
    ├── CodeStructureChunkerSpec.swift
    └── SemanticChunkerSpec.swift
```

## Writing Integration Tests

### 1. Extend IntegrationTestCase

```swift
import XCTest
@testable import InfrastructureCore
@testable import Domain

final class MyRepositoryIntegrationSpec: IntegrationTestCase {
    // setUp() automatically:
    // - Starts TestDatabaseManager
    // - Waits for database ready
    // - Creates SupabaseClient

    func testMyFeature() async throws {
        // Use self.supabaseClient for REAL database access
        let repository = MyRepository(client: supabaseClient)

        // Test REAL operations
        let result = try await repository.save(data)
        XCTAssertNotNil(result)
    }

    // tearDown() automatically:
    // - Cleans ALL test data
    // - Ensures test isolation
}
```

### 2. Test Real Implementation

**✅ CORRECT - Test REAL implementation:**
```swift
func testSave_withRealDatabase() async throws {
    // Create REAL repository
    let repository = SupabasePRDRepository(client: supabaseClient)

    // Call REAL save method
    let saved = try await repository.save(document)

    // Verify in REAL database
    let found = try await repository.findById(saved.id)
    XCTAssertEqual(found?.id, saved.id)
}
```

**❌ WRONG - Test mock logic:**
```swift
func testSave_withMock() async throws {
    // ❌ Using mock repository
    let mockRepo = MockPRDRepository()

    // ❌ Testing mock implementation, not REAL code
    await mockRepo.save(document)
    // This tests NOTHING about real database operations!
}
```

### 3. Test Database Constraints

```swift
func testSave_enforcesUniqueConstraint() async throws {
    let repository = SupabasePRDRepository(client: supabaseClient)

    let document = PRDDocument(id: UUID(), ...)

    // First save succeeds
    _ = try await repository.save(document)

    // Second save with same ID should fail
    do {
        _ = try await repository.save(document)
        XCTFail("Should throw unique constraint error")
    } catch {
        // Expected - REAL database enforces constraints
        XCTAssertTrue("\(error)".contains("unique"))
    }
}
```

### 4. Test Foreign Key Relationships

```swift
func testSave_enforcesForeignKeys() async throws {
    let repository = SupabaseCodeFileRepository(client: supabaseClient)

    // Try to save file without codebase (invalid FK)
    let file = CodeFile(
        codebaseId: UUID(),  // Nonexistent codebase
        filePath: "test.swift",
        ...
    )

    // Should fail - REAL database enforces FK
    do {
        _ = try await repository.save(file)
        XCTFail("Should throw foreign key error")
    } catch {
        // Expected
    }
}
```

### 5. Test Transactions

```swift
func testSaveBatch_rollsBackOnError() async throws {
    let repository = SupabaseCodeChunkRepository(client: supabaseClient)

    let chunks = [
        validChunk1,
        invalidChunk,  // Will cause error
        validChunk2
    ]

    // Should rollback entire batch
    do {
        _ = try await repository.saveBatch(chunks)
        XCTFail("Should rollback transaction")
    } catch {
        // Expected
    }

    // Verify REAL database rolled back
    let saved = try await repository.findAll()
    XCTAssertEqual(saved.count, 0)  // Nothing saved
}
```

## Test Isolation

**Each test gets clean database:**

```swift
// Test 1
func testFirstOperation() async throws {
    _ = try await repository.save(doc1)
    // tearDown() cleans database
}

// Test 2 starts with empty database
func testSecondOperation() async throws {
    let all = try await repository.findAll()
    XCTAssertEqual(all.count, 0)  // ✅ Clean state
}
```

**Guaranteed by:**
1. `IntegrationTestCase.tearDown()` calls `testDB.cleanDatabase()`
2. Database executes `truncate_all_tables()` function
3. All tables reset to empty state

## Prerequisites

### 1. Docker Installed

```bash
docker --version
# Docker version 24.0.0 or later
```

### 2. Test Database Running

```bash
cd docker/test-db
docker-compose up -d
docker-compose ps

# Should show:
# ai-prd-test-postgres    Up (healthy)
# ai-prd-test-postgrest   Up (healthy)
```

### 3. Database Schema Created

Schema is automatically created from `docker/test-db/init.sql` on first start.

**Verify:**
```bash
docker exec ai-prd-test-postgres psql -U postgres -d ai_prd_test -c "\dt"
# Should list: prd_documents, codebases, code_files, etc.
```

## Troubleshooting

### Tests fail with "database not accessible"

```bash
# Check database health
cd docker/test-db
docker-compose ps

# Restart if unhealthy
docker-compose restart

# Check logs
docker-compose logs
```

### Tests fail with "table does not exist"

```bash
# Schema might not be initialized
docker-compose down -v  # Remove volumes
docker-compose up -d    # Recreate with init.sql
```

### Tests are slow

```bash
# Check Docker resource limits
# Increase CPU/Memory in Docker Desktop settings

# Or run fewer tests in parallel
swift test --parallel --num-workers 4
```

### Database has stale data

```bash
# Manually truncate (shouldn't be needed if tearDown works)
docker exec ai-prd-test-postgres psql -U postgres -d ai_prd_test \
  -c "SELECT truncate_all_tables();"
```

## CI/CD

### GitHub Actions

```yaml
jobs:
  integration-tests:
    runs-on: macos-latest

    services:
      postgres:
        image: ankane/pgvector:latest
        env:
          POSTGRES_DB: ai_prd_test
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        ports:
          - 54322:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      postgrest:
        image: postgrest/postgrest:latest
        env:
          PGRST_DB_URI: postgres://postgres:postgres@postgres:5432/ai_prd_test
          PGRST_DB_SCHEMA: public
          PGRST_DB_ANON_ROLE: postgres
        ports:
          - 54321:3000

    steps:
      - uses: actions/checkout@v3

      - name: Run integration tests
        run: |
          cd library
          swift test --filter "IntegrationSpec"
```

## Resources

- **[Local Test Database Setup](../../docker/test-db/README.md)** - Docker setup
- **[Test README](../README.md)** - Overall test strategy
- **[CLAUDE.md](../../CLAUDE.md)** - Testing standards

---

**Remember:** Mocks test mock logic. Real databases test real implementation. Always prefer real integration tests for infrastructure code.
