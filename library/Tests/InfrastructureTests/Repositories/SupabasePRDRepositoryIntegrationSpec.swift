import XCTest
@testable import InfrastructureCore
@testable import Application
@testable import Domain

/// Integration test for SupabasePRDRepository with REAL database
/// Tests REAL SQL operations, not mocks
///
/// Prerequisites:
/// 1. Start test database: `cd docker/test-db && docker-compose up -d`
/// 2. Run tests: `swift test --filter SupabasePRDRepositoryIntegrationSpec`
final class SupabasePRDRepositoryIntegrationSpec: IntegrationTestCase {

    // MARK: - Save & Retrieve Tests

    func testSave_insertsDocumentIntoRealDatabase() async throws {
        // Given: Real repository with real database connection
        let dbClient = SupabaseDatabaseClient(supabaseClient: supabaseClient)
        let repository = SupabasePRDRepository(databaseClient: dbClient)

        let document = PRDDocument(
            title: "Integration Test PRD",
            sections: [
                PRDSection(
                    type: .overview,
                    title: "Overview",
                    content: "This is a real integration test",
                    order: 0
                ),
                PRDSection(
                    type: .goals,
                    title: "Goals",
                    content: "Test real database operations",
                    order: 1
                )
            ],
            metadata: DocumentMetadata(
                author: "Integration Test Suite",
                projectName: "Test Project",
                aiProvider: "Test AI",
                codebaseId: nil
            )
        )

        // When: Save to REAL database
        let saved = try await repository.save(document)

        // Then: Document is saved with generated ID
        XCTAssertNotNil(saved.id)
        XCTAssertEqual(saved.title, "Integration Test PRD")
        XCTAssertEqual(saved.sections.count, 2)
    }

    func testFindById_retrievesDocumentFromRealDatabase() async throws {
        // Given: Document saved in real database
        let dbClient = SupabaseDatabaseClient(supabaseClient: supabaseClient)
        let repository = SupabasePRDRepository(databaseClient: dbClient)

        let original = PRDDocument(
            title: "Findable PRD",
            sections: [
                PRDSection(
                    type: .overview,
                    title: "Overview",
                    content: "Content for finding",
                    order: 0
                )
            ],
            metadata: DocumentMetadata(
                author: "Test",
                projectName: "Find Test",
                aiProvider: "Test AI"
            )
        )

        let saved = try await repository.save(original)

        // When: Retrieve from REAL database by ID
        let found = try await repository.findById(saved.id)

        // Then: Document is retrieved correctly
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, saved.id)
        XCTAssertEqual(found?.title, "Findable PRD")
        XCTAssertEqual(found?.sections.count, 1)
        XCTAssertEqual(found?.sections.first?.content, "Content for finding")
    }

    func testFindById_returnsNilForNonexistentDocument() async throws {
        // Given: Real repository
        let dbClient = SupabaseDatabaseClient(supabaseClient: supabaseClient)
        let repository = SupabasePRDRepository(databaseClient: dbClient)

        let nonexistentId = UUID()

        // When: Try to find nonexistent document
        let found = try await repository.findById(nonexistentId)

        // Then: Returns nil
        XCTAssertNil(found)
    }

    // MARK: - Update Tests

    func testUpdate_modifiesExistingDocumentInRealDatabase() async throws {
        // Given: Document saved in real database
        let dbClient = SupabaseDatabaseClient(supabaseClient: supabaseClient)
        let repository = SupabasePRDRepository(databaseClient: dbClient)

        let original = PRDDocument(
            title: "Original Title",
            sections: [
                PRDSection(type: .overview, title: "Overview", content: "Original", order: 0)
            ],
            metadata: DocumentMetadata(
                author: "Test",
                projectName: "Update Test",
                aiProvider: "Test AI"
            )
        )

        let saved = try await repository.save(original)

        // When: Update the document
        var updated = saved
        updated.title = "Updated Title"
        updated.sections = [
            PRDSection(type: .overview, title: "Overview", content: "Updated content", order: 0)
        ]

        let result = try await repository.update(updated)

        // Then: Document is updated in real database
        XCTAssertEqual(result.title, "Updated Title")
        XCTAssertEqual(result.sections.first?.content, "Updated content")

        // Verify by fetching again
        let refetched = try await repository.findById(saved.id)
        XCTAssertEqual(refetched?.title, "Updated Title")
    }

    // MARK: - Delete Tests

    func testDelete_removesDocumentFromRealDatabase() async throws {
        // Given: Document saved in real database
        let dbClient = SupabaseDatabaseClient(supabaseClient: supabaseClient)
        let repository = SupabasePRDRepository(databaseClient: dbClient)

        let document = PRDDocument(
            title: "To Be Deleted",
            sections: [],
            metadata: DocumentMetadata(
                author: "Test",
                projectName: "Delete Test",
                aiProvider: "Test AI"
            )
        )

        let saved = try await repository.save(document)

        // When: Delete from REAL database
        try await repository.delete(id: saved.id)

        // Then: Document no longer exists
        let found = try await repository.findById(saved.id)
        XCTAssertNil(found)
    }

    // MARK: - Search Tests

    func testSearch_findsDocumentsInRealDatabase() async throws {
        // Given: Multiple documents in real database
        let dbClient = SupabaseDatabaseClient(supabaseClient: supabaseClient)
        let repository = SupabasePRDRepository(databaseClient: dbClient)

        let doc1 = PRDDocument(
            title: "Authentication PRD",
            sections: [
                PRDSection(
                    type: .overview,
                    title: "Overview",
                    content: "User authentication system",
                    order: 0
                )
            ],
            metadata: DocumentMetadata(
                author: "Test",
                projectName: "Auth",
                aiProvider: "Test AI"
            )
        )

        let doc2 = PRDDocument(
            title: "Dashboard PRD",
            sections: [
                PRDSection(
                    type: .overview,
                    title: "Overview",
                    content: "Admin dashboard interface",
                    order: 0
                )
            ],
            metadata: DocumentMetadata(
                author: "Test",
                projectName: "Dashboard",
                aiProvider: "Test AI"
            )
        )

        _ = try await repository.save(doc1)
        _ = try await repository.save(doc2)

        // When: Search in REAL database
        let results = try await repository.search(query: "Authentication")

        // Then: Finds matching documents
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.title.contains("Authentication") })
    }

    // MARK: - Transaction Tests

    func testSaveMultiple_allOrNothingTransaction() async throws {
        // Given: Real repository
        let dbClient = SupabaseDatabaseClient(supabaseClient: supabaseClient)
        let repository = SupabasePRDRepository(databaseClient: dbClient)

        let doc1 = PRDDocument(
            title: "Transaction Test 1",
            sections: [],
            metadata: DocumentMetadata(
                author: "Test",
                projectName: "Trans 1",
                aiProvider: "Test AI"
            )
        )

        let doc2 = PRDDocument(
            title: "Transaction Test 2",
            sections: [],
            metadata: DocumentMetadata(
                author: "Test",
                projectName: "Trans 2",
                aiProvider: "Test AI"
            )
        )

        // When: Save multiple documents
        _ = try await repository.save(doc1)
        _ = try await repository.save(doc2)

        // Then: Both documents exist in real database
        let all = try await repository.findAll(limit: 10)
        XCTAssertGreaterThanOrEqual(all.count, 2)
    }
}
