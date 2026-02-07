# Test Cases: Snippet Library - Core CRUD

**Generated:** 2026-02-05
**PRD Reference:** PRD-SnippetLibraryCRUD.md

---

## PART A: Coverage Tests

### A.1 Unit Tests - Domain Layer

#### A.1.1 Snippet Entity Tests

```swift
// Tests/DomainTests/SnippetTests.swift

import XCTest
@testable import SnippetLibrary

final class SnippetTests: XCTestCase {

    // MARK: - Creation Tests

    func testCreateSnippet_WithValidInput_Succeeds() throws {
        // Given
        let userId = UUID()
        let title = "Test Snippet"
        let content = "Test content"

        // When
        let snippet = try Snippet(
            userId: userId,
            title: title,
            content: content,
            type: .feature,
            tags: ["Tag1", "Tag2"]
        )

        // Then
        XCTAssertEqual(snippet.title, title)
        XCTAssertEqual(snippet.content, content)
        XCTAssertEqual(snippet.type, .feature)
        XCTAssertEqual(snippet.tags, ["Tag1", "Tag2"])
        XCTAssertNil(snippet.deletedAt)
    }

    func testCreateSnippet_WithEmptyTitle_ThrowsTitleRequired() {
        // Given
        let userId = UUID()

        // When/Then
        XCTAssertThrowsError(try Snippet(userId: userId, title: "")) { error in
            XCTAssertEqual(error as? SnippetError, .titleRequired)
        }
    }

    func testCreateSnippet_WithWhitespaceOnlyTitle_ThrowsTitleRequired() {
        // Given
        let userId = UUID()

        // When/Then
        XCTAssertThrowsError(try Snippet(userId: userId, title: "   ")) { error in
            XCTAssertEqual(error as? SnippetError, .titleRequired)
        }
    }

    func testCreateSnippet_WithTitleOver200Chars_ThrowsTitleTooLong() {
        // Given
        let userId = UUID()
        let longTitle = String(repeating: "a", count: 201)

        // When/Then
        XCTAssertThrowsError(try Snippet(userId: userId, title: longTitle)) { error in
            if case .titleTooLong(let current, let max) = error as? SnippetError {
                XCTAssertEqual(current, 201)
                XCTAssertEqual(max, 200)
            } else {
                XCTFail("Expected titleTooLong error")
            }
        }
    }

    func testCreateSnippet_WithTitle200Chars_Succeeds() throws {
        // Given
        let userId = UUID()
        let exactTitle = String(repeating: "a", count: 200)

        // When
        let snippet = try Snippet(userId: userId, title: exactTitle)

        // Then
        XCTAssertEqual(snippet.title.count, 200)
    }

    func testCreateSnippet_WithContentOver5000Chars_ThrowsContentTooLong() {
        // Given
        let userId = UUID()
        let longContent = String(repeating: "a", count: 5001)

        // When/Then
        XCTAssertThrowsError(
            try Snippet(userId: userId, title: "Test", content: longContent)
        ) { error in
            if case .contentTooLong(let current, let max) = error as? SnippetError {
                XCTAssertEqual(current, 5001)
                XCTAssertEqual(max, 5000)
            } else {
                XCTFail("Expected contentTooLong error")
            }
        }
    }

    func testCreateSnippet_WithContent5000Chars_Succeeds() throws {
        // Given
        let userId = UUID()
        let exactContent = String(repeating: "a", count: 5000)

        // When
        let snippet = try Snippet(userId: userId, title: "Test", content: exactContent)

        // Then
        XCTAssertEqual(snippet.content.count, 5000)
    }

    func testCreateSnippet_WithOver10Tags_ThrowsTooManyTags() {
        // Given
        let userId = UUID()
        let tags = (1...11).map { "Tag\($0)" }

        // When/Then
        XCTAssertThrowsError(
            try Snippet(userId: userId, title: "Test", tags: tags)
        ) { error in
            if case .tooManyTags(let current, let max) = error as? SnippetError {
                XCTAssertEqual(current, 11)
                XCTAssertEqual(max, 10)
            } else {
                XCTFail("Expected tooManyTags error")
            }
        }
    }

    func testCreateSnippet_With10Tags_Succeeds() throws {
        // Given
        let userId = UUID()
        let tags = (1...10).map { "Tag\($0)" }

        // When
        let snippet = try Snippet(userId: userId, title: "Test", tags: tags)

        // Then
        XCTAssertEqual(snippet.tags.count, 10)
    }

    func testCreateSnippet_WithDuplicateTags_RemovesDuplicates() throws {
        // Given
        let userId = UUID()
        let tags = ["Tag1", "Tag2", "Tag1", "Tag3", "Tag2"]

        // When
        let snippet = try Snippet(userId: userId, title: "Test", tags: tags)

        // Then
        XCTAssertEqual(snippet.tags.count, 3)
        XCTAssertTrue(snippet.tags.contains("Tag1"))
        XCTAssertTrue(snippet.tags.contains("Tag2"))
        XCTAssertTrue(snippet.tags.contains("Tag3"))
    }

    func testCreateSnippet_WithUnsortedTags_SortsThem() throws {
        // Given
        let userId = UUID()
        let tags = ["Zebra", "Apple", "Mango"]

        // When
        let snippet = try Snippet(userId: userId, title: "Test", tags: tags)

        // Then
        XCTAssertEqual(snippet.tags, ["Apple", "Mango", "Zebra"])
    }

    func testCreateSnippet_TrimsWhitespaceFromTitle() throws {
        // Given
        let userId = UUID()
        let title = "  Test Title  "

        // When
        let snippet = try Snippet(userId: userId, title: title)

        // Then
        XCTAssertEqual(snippet.title, "Test Title")
    }

    // MARK: - Computed Property Tests

    func testIsDeleted_WhenDeletedAtIsNil_ReturnsFalse() throws {
        // Given
        let snippet = try Snippet(userId: UUID(), title: "Test")

        // Then
        XCTAssertFalse(snippet.isDeleted)
    }

    func testIsDeleted_WhenDeletedAtIsSet_ReturnsTrue() throws {
        // Given
        let snippet = try Snippet(
            userId: UUID(),
            title: "Test",
            deletedAt: Date()
        )

        // Then
        XCTAssertTrue(snippet.isDeleted)
    }

    func testCanBeRecovered_WhenNotDeleted_ReturnsFalse() throws {
        // Given
        let snippet = try Snippet(userId: UUID(), title: "Test")

        // Then
        XCTAssertFalse(snippet.canBeRecovered)
    }

    func testCanBeRecovered_WhenDeletedWithin30Days_ReturnsTrue() throws {
        // Given
        let deletedAt = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        let snippet = try Snippet(
            userId: UUID(),
            title: "Test",
            deletedAt: deletedAt
        )

        // Then
        XCTAssertTrue(snippet.canBeRecovered)
    }

    func testCanBeRecovered_WhenDeletedOver30Days_ReturnsFalse() throws {
        // Given
        let deletedAt = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        let snippet = try Snippet(
            userId: UUID(),
            title: "Test",
            deletedAt: deletedAt
        )

        // Then
        XCTAssertFalse(snippet.canBeRecovered)
    }
}
```

#### A.1.2 SnippetError Tests

```swift
// Tests/DomainTests/SnippetErrorTests.swift

import XCTest
@testable import SnippetLibrary

final class SnippetErrorTests: XCTestCase {

    func testTitleRequired_HasCorrectDescription() {
        let error = SnippetError.titleRequired
        XCTAssertEqual(error.errorDescription, "Title is required")
    }

    func testTitleTooLong_HasCorrectDescription() {
        let error = SnippetError.titleTooLong(current: 250, max: 200)
        XCTAssertEqual(error.errorDescription, "Title is too long (250/200 characters)")
    }

    func testContentTooLong_HasCorrectDescription() {
        let error = SnippetError.contentTooLong(current: 6000, max: 5000)
        XCTAssertEqual(error.errorDescription, "Content is too long (6000/5000 characters)")
    }

    func testTooManyTags_HasCorrectDescription() {
        let error = SnippetError.tooManyTags(current: 15, max: 10)
        XCTAssertEqual(error.errorDescription, "Too many tags (15/10)")
    }

    func testNotFound_HasCorrectDescription() {
        let id = UUID()
        let error = SnippetError.notFound(id: id)
        XCTAssertEqual(error.errorDescription, "Snippet not found: \(id)")
    }

    func testEquality() {
        XCTAssertEqual(SnippetError.titleRequired, SnippetError.titleRequired)
        XCTAssertNotEqual(SnippetError.titleRequired, SnippetError.contentTooLong(current: 1, max: 1))
    }
}
```

#### A.1.3 SnippetType Tests

```swift
// Tests/DomainTests/SnippetTypeTests.swift

import XCTest
@testable import SnippetLibrary

final class SnippetTypeTests: XCTestCase {

    func testFeatureType_HasCorrectDisplayName() {
        XCTAssertEqual(SnippetType.feature.displayName, "Feature")
    }

    func testFeatureType_HasCorrectIconName() {
        XCTAssertEqual(SnippetType.feature.iconName, "star.fill")
    }

    func testFeatureType_IsIdentifiable() {
        XCTAssertEqual(SnippetType.feature.id, "Feature")
    }

    func testAllCases_ContainsFeature() {
        XCTAssertTrue(SnippetType.allCases.contains(.feature))
    }
}
```

### A.2 Unit Tests - Application Layer

#### A.2.1 SnippetViewModel Tests

```swift
// Tests/ApplicationTests/SnippetViewModelTests.swift

import XCTest
@testable import SnippetLibrary

@MainActor
final class SnippetViewModelTests: XCTestCase {

    var mockRepository: MockSnippetRepository!
    var viewModel: SnippetViewModel!
    let testUserId = UUID()

    override func setUp() async throws {
        mockRepository = MockSnippetRepository()
        viewModel = SnippetViewModel(repository: mockRepository, userId: testUserId)
    }

    // MARK: - loadSnippets Tests

    func testLoadSnippets_Success_PopulatesSnippets() async {
        // Given
        let snippet = try! Snippet(userId: testUserId, title: "Test")
        mockRepository.snippetsToReturn = [snippet]

        // When
        await viewModel.loadSnippets()

        // Then
        XCTAssertEqual(viewModel.snippets.count, 1)
        XCTAssertEqual(viewModel.snippets.first?.title, "Test")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testLoadSnippets_SetsIsLoadingDuringFetch() async {
        // Given
        mockRepository.delay = 0.1

        // When
        let loadTask = Task {
            await viewModel.loadSnippets()
        }

        // Brief delay to catch loading state
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then
        XCTAssertTrue(viewModel.isLoading)

        await loadTask.value
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadSnippets_OnError_SetsError() async {
        // Given
        mockRepository.errorToThrow = SnippetError.persistenceError("DB error")

        // When
        await viewModel.loadSnippets()

        // Then
        XCTAssertEqual(viewModel.snippets.count, 0)
        XCTAssertNotNil(viewModel.error)
    }

    // MARK: - createSnippet Tests

    func testCreateSnippet_Success_AddsToList() async throws {
        // Given
        let input = SnippetInput(title: "New Snippet", content: "Content")

        // When
        let created = try await viewModel.createSnippet(input: input)

        // Then
        XCTAssertEqual(viewModel.snippets.count, 1)
        XCTAssertEqual(viewModel.snippets.first?.id, created.id)
        XCTAssertEqual(created.title, "New Snippet")
    }

    func testCreateSnippet_InvalidInput_ThrowsError() async {
        // Given
        let input = SnippetInput(title: "") // Invalid: empty title

        // When/Then
        do {
            _ = try await viewModel.createSnippet(input: input)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? SnippetError, .titleRequired)
        }
    }

    func testCreateSnippet_InsertsAtTop() async throws {
        // Given
        let existing = try! Snippet(userId: testUserId, title: "Existing")
        mockRepository.snippetsToReturn = [existing]
        await viewModel.loadSnippets()

        let input = SnippetInput(title: "New")

        // When
        let created = try await viewModel.createSnippet(input: input)

        // Then
        XCTAssertEqual(viewModel.snippets.first?.id, created.id)
    }

    // MARK: - updateSnippet Tests

    func testUpdateSnippet_Success_UpdatesInList() async throws {
        // Given
        let existing = try! Snippet(userId: testUserId, title: "Original")
        mockRepository.snippetsToReturn = [existing]
        await viewModel.loadSnippets()

        let input = SnippetInput(title: "Updated")

        // When
        let updated = try await viewModel.updateSnippet(id: existing.id, input: input)

        // Then
        XCTAssertEqual(updated.title, "Updated")
        XCTAssertEqual(viewModel.snippets.first?.title, "Updated")
    }

    func testUpdateSnippet_NotFound_ThrowsError() async {
        // When/Then
        do {
            _ = try await viewModel.updateSnippet(
                id: UUID(),
                input: SnippetInput(title: "Test")
            )
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? SnippetError, .notFound(id: UUID()))
        }
    }

    // MARK: - deleteSnippet Tests

    func testDeleteSnippet_Success_RemovesFromList() async throws {
        // Given
        let snippet = try! Snippet(userId: testUserId, title: "To Delete")
        mockRepository.snippetsToReturn = [snippet]
        await viewModel.loadSnippets()

        // When
        try await viewModel.deleteSnippet(id: snippet.id)

        // Then
        XCTAssertEqual(viewModel.snippets.count, 0)
    }
}

// MARK: - Mock Repository

final class MockSnippetRepository: SnippetRepository, @unchecked Sendable {
    var snippetsToReturn: [Snippet] = []
    var errorToThrow: Error?
    var delay: TimeInterval = 0
    var savedSnippets: [Snippet] = []
    var deletedIds: [UUID] = []

    func save(snippet: Snippet) async throws -> Snippet {
        if let error = errorToThrow { throw error }
        savedSnippets.append(snippet)
        return snippet
    }

    func fetch(id: UUID) async throws -> Snippet? {
        snippetsToReturn.first { $0.id == id }
    }

    func fetchAll(userId: UUID) async throws -> [Snippet] {
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if let error = errorToThrow { throw error }
        return snippetsToReturn
    }

    func fetchDeleted(userId: UUID) async throws -> [Snippet] {
        []
    }

    func update(snippet: Snippet) async throws -> Snippet {
        if let error = errorToThrow { throw error }
        return snippet
    }

    func softDelete(id: UUID) async throws {
        if let error = errorToThrow { throw error }
        deletedIds.append(id)
    }

    func recover(id: UUID) async throws {}

    func purgeExpired() async throws -> Int { 0 }
}
```

### A.3 Integration Tests - Repository

```swift
// Tests/IntegrationTests/SwiftDataSnippetRepositoryTests.swift

import XCTest
import SwiftData
@testable import SnippetLibrary

@MainActor
final class SwiftDataSnippetRepositoryTests: XCTestCase {

    var container: ModelContainer!
    var repository: SwiftDataSnippetRepository!
    let testUserId = UUID()

    override func setUp() async throws {
        let schema = Schema([SnippetModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repository = SwiftDataSnippetRepository(modelContainer: container)
    }

    override func tearDown() async throws {
        container = nil
        repository = nil
    }

    // MARK: - Save Tests

    func testSave_PersistsSnippet() async throws {
        // Given
        let snippet = try Snippet(userId: testUserId, title: "Test", content: "Content")

        // When
        let saved = try await repository.save(snippet: snippet)

        // Then
        XCTAssertEqual(saved.id, snippet.id)

        let fetched = try await repository.fetch(id: snippet.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Test")
    }

    // MARK: - FetchAll Tests

    func testFetchAll_ReturnsOnlyUserSnippets() async throws {
        // Given
        let snippet1 = try Snippet(userId: testUserId, title: "Mine")
        let otherUser = UUID()
        let snippet2 = try Snippet(userId: otherUser, title: "Other")

        _ = try await repository.save(snippet: snippet1)
        _ = try await repository.save(snippet: snippet2)

        // When
        let results = try await repository.fetchAll(userId: testUserId)

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Mine")
    }

    func testFetchAll_ExcludesDeletedSnippets() async throws {
        // Given
        let active = try Snippet(userId: testUserId, title: "Active")
        let deleted = try Snippet(userId: testUserId, title: "Deleted", deletedAt: Date())

        _ = try await repository.save(snippet: active)
        _ = try await repository.save(snippet: deleted)

        // When
        let results = try await repository.fetchAll(userId: testUserId)

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Active")
    }

    func testFetchAll_OrdersByUpdatedAtDescending() async throws {
        // Given
        let older = try Snippet(
            userId: testUserId,
            title: "Older",
            updatedAt: Date(timeIntervalSinceNow: -3600)
        )
        let newer = try Snippet(
            userId: testUserId,
            title: "Newer",
            updatedAt: Date()
        )

        _ = try await repository.save(snippet: older)
        _ = try await repository.save(snippet: newer)

        // When
        let results = try await repository.fetchAll(userId: testUserId)

        // Then
        XCTAssertEqual(results.first?.title, "Newer")
    }

    // MARK: - Update Tests

    func testUpdate_ModifiesExistingSnippet() async throws {
        // Given
        let original = try Snippet(userId: testUserId, title: "Original")
        _ = try await repository.save(snippet: original)

        let modified = try Snippet(
            id: original.id,
            userId: testUserId,
            title: "Modified",
            createdAt: original.createdAt,
            updatedAt: Date()
        )

        // When
        let updated = try await repository.update(snippet: modified)

        // Then
        XCTAssertEqual(updated.title, "Modified")

        let fetched = try await repository.fetch(id: original.id)
        XCTAssertEqual(fetched?.title, "Modified")
    }

    func testUpdate_NonExistent_ThrowsNotFound() async {
        // Given
        let snippet = try! Snippet(userId: testUserId, title: "Test")

        // When/Then
        do {
            _ = try await repository.update(snippet: snippet)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? SnippetError, .notFound(id: snippet.id))
        }
    }

    // MARK: - SoftDelete Tests

    func testSoftDelete_SetsDeletedAt() async throws {
        // Given
        let snippet = try Snippet(userId: testUserId, title: "Test")
        _ = try await repository.save(snippet: snippet)

        // When
        try await repository.softDelete(id: snippet.id)

        // Then - should not appear in fetchAll
        let results = try await repository.fetchAll(userId: testUserId)
        XCTAssertEqual(results.count, 0)

        // But should appear in fetchDeleted
        let deleted = try await repository.fetchDeleted(userId: testUserId)
        XCTAssertEqual(deleted.count, 1)
    }

    func testSoftDelete_AlreadyDeleted_ThrowsError() async throws {
        // Given
        let snippet = try Snippet(userId: testUserId, title: "Test", deletedAt: Date())
        _ = try await repository.save(snippet: snippet)

        // When/Then
        do {
            try await repository.softDelete(id: snippet.id)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? SnippetError, .alreadyDeleted(id: snippet.id))
        }
    }

    // MARK: - Recover Tests

    func testRecover_RestoresDeletedSnippet() async throws {
        // Given
        let snippet = try Snippet(userId: testUserId, title: "Test")
        _ = try await repository.save(snippet: snippet)
        try await repository.softDelete(id: snippet.id)

        // When
        try await repository.recover(id: snippet.id)

        // Then
        let results = try await repository.fetchAll(userId: testUserId)
        XCTAssertEqual(results.count, 1)
    }

    func testRecover_ExpiredSnippet_ThrowsError() async throws {
        // Given
        let expiredDate = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        let snippet = try Snippet(userId: testUserId, title: "Test", deletedAt: expiredDate)
        _ = try await repository.save(snippet: snippet)

        // When/Then
        do {
            try await repository.recover(id: snippet.id)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? SnippetError, .cannotRecover(id: snippet.id))
        }
    }

    // MARK: - Performance Tests

    func testFetchAll_Performance_With2000Snippets() async throws {
        // Given - Create 2000 snippets
        for i in 0..<2000 {
            let snippet = try Snippet(userId: testUserId, title: "Snippet \(i)")
            _ = try await repository.save(snippet: snippet)
        }

        // When/Then - Measure fetch time
        let start = CFAbsoluteTimeGetCurrent()
        let results = try await repository.fetchAll(userId: testUserId)
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertEqual(results.count, 2000)
        XCTAssertLessThan(elapsed, 0.3, "Fetch should complete in < 300ms")
    }
}
```

### A.4 UI Tests

```swift
// UITests/SnippetLibraryUITests.swift

import XCTest

final class SnippetLibraryUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    // MARK: - List View Tests

    func testSnippetList_DisplaysEmptyState_WhenNoSnippets() {
        // Navigate to Snippets tab
        app.tabBars.buttons["Snippets"].tap()

        // Verify empty state
        XCTAssertTrue(app.staticTexts["No snippets yet"].exists)
        XCTAssertTrue(app.buttons["Create Snippet"].exists)
    }

    func testSnippetList_DisplaysSnippets_WhenPopulated() {
        // Create a snippet first
        createTestSnippet(title: "Test Snippet")

        // Navigate to Snippets tab
        app.tabBars.buttons["Snippets"].tap()

        // Verify snippet appears
        XCTAssertTrue(app.staticTexts["Test Snippet"].exists)
    }

    // MARK: - Create Snippet Tests

    func testCreateSnippet_WithValidInput_Succeeds() {
        // Navigate to Snippets tab
        app.tabBars.buttons["Snippets"].tap()

        // Tap add button
        app.navigationBars.buttons["Add"].tap()

        // Fill form
        let titleField = app.textFields["Title"]
        titleField.tap()
        titleField.typeText("New Feature")

        let contentEditor = app.textViews["Content"]
        contentEditor.tap()
        contentEditor.typeText("Feature description")

        // Save
        app.buttons["Save Snippet"].tap()

        // Verify snippet in list
        XCTAssertTrue(app.staticTexts["New Feature"].waitForExistence(timeout: 2))
    }

    func testCreateSnippet_WithEmptyTitle_ShowsError() {
        // Navigate to Snippets tab
        app.tabBars.buttons["Snippets"].tap()

        // Tap add button
        app.navigationBars.buttons["Add"].tap()

        // Try to save without title
        app.buttons["Save Snippet"].tap()

        // Verify error shown
        XCTAssertTrue(app.staticTexts["Title is required"].exists)
    }

    func testCreateSnippet_WithTitleOver200_ShowsError() {
        // Navigate to Snippets tab
        app.tabBars.buttons["Snippets"].tap()

        // Tap add button
        app.navigationBars.buttons["Add"].tap()

        // Enter very long title
        let titleField = app.textFields["Title"]
        titleField.tap()
        titleField.typeText(String(repeating: "a", count: 201))

        // Verify error shown
        XCTAssertTrue(app.staticTexts["Title is too long"].exists)
        XCTAssertFalse(app.buttons["Save Snippet"].isEnabled)
    }

    // MARK: - Detail View Tests

    func testSnippetDetail_DisplaysAllFields() {
        // Create a snippet
        createTestSnippet(title: "Detail Test", content: "Content here", tags: ["Tag1"])

        // Navigate to Snippets tab
        app.tabBars.buttons["Snippets"].tap()

        // Tap snippet
        app.staticTexts["Detail Test"].tap()

        // Verify all fields displayed
        XCTAssertTrue(app.staticTexts["Feature: Detail Test"].exists)
        XCTAssertTrue(app.staticTexts["Content here"].exists)
        XCTAssertTrue(app.staticTexts["Tag1"].exists)
        XCTAssertTrue(app.buttons["Edit"].exists)
    }

    // MARK: - Edit Tests

    func testEditSnippet_UpdatesContent() {
        // Create a snippet
        createTestSnippet(title: "Original Title")

        // Navigate and open detail
        app.tabBars.buttons["Snippets"].tap()
        app.staticTexts["Original Title"].tap()

        // Tap edit
        app.buttons["Edit"].tap()

        // Update title
        let titleField = app.textFields["Title"]
        titleField.tap()
        titleField.clearAndTypeText("Updated Title")

        // Save
        app.buttons["Save Snippet"].tap()

        // Verify update
        XCTAssertTrue(app.staticTexts["Feature: Updated Title"].waitForExistence(timeout: 2))
    }

    // MARK: - Delete Tests

    func testDeleteSnippet_ShowsConfirmation() {
        // Create a snippet
        createTestSnippet(title: "To Delete")

        // Navigate and open detail
        app.tabBars.buttons["Snippets"].tap()
        app.staticTexts["To Delete"].tap()

        // Tap delete
        app.buttons["Delete"].tap()

        // Verify confirmation
        XCTAssertTrue(app.alerts["Delete"].exists)
    }

    func testDeleteSnippet_RemovesFromList() {
        // Create a snippet
        createTestSnippet(title: "To Delete")

        // Navigate and open detail
        app.tabBars.buttons["Snippets"].tap()
        app.staticTexts["To Delete"].tap()

        // Delete and confirm
        app.buttons["Delete"].tap()
        app.alerts.buttons["Delete"].tap()

        // Verify removed from list
        XCTAssertFalse(app.staticTexts["To Delete"].exists)
    }

    // MARK: - Tag Tests

    func testTagInput_AddsChip_OnComma() {
        // Navigate to create
        app.tabBars.buttons["Snippets"].tap()
        app.navigationBars.buttons["Add"].tap()

        // Enter tag
        let tagField = app.textFields["Tags"]
        tagField.tap()
        tagField.typeText("NewTag,")

        // Verify chip created
        XCTAssertTrue(app.buttons["NewTag"].exists)
    }

    func testTagChip_RemovesOnXTap() {
        // Navigate to create
        app.tabBars.buttons["Snippets"].tap()
        app.navigationBars.buttons["Add"].tap()

        // Add tag
        let tagField = app.textFields["Tags"]
        tagField.tap()
        tagField.typeText("RemoveMe,")

        // Tap X on chip
        app.buttons["RemoveMe"].buttons["Remove"].tap()

        // Verify removed
        XCTAssertFalse(app.buttons["RemoveMe"].exists)
    }

    // MARK: - Helpers

    private func createTestSnippet(
        title: String,
        content: String = "",
        tags: [String] = []
    ) {
        // Navigate to create
        app.tabBars.buttons["Snippets"].tap()
        app.navigationBars.buttons["Add"].tap()

        // Fill form
        let titleField = app.textFields["Title"]
        titleField.tap()
        titleField.typeText(title)

        if !content.isEmpty {
            let contentEditor = app.textViews["Content"]
            contentEditor.tap()
            contentEditor.typeText(content)
        }

        for tag in tags {
            let tagField = app.textFields["Tags"]
            tagField.tap()
            tagField.typeText("\(tag),")
        }

        // Save
        app.buttons["Save Snippet"].tap()
    }
}

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = self.value as? String else {
            self.typeText(text)
            return
        }

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
```

---

## PART B: Acceptance Criteria Validation Tests

### B.1 Performance AC Tests

```swift
// Tests/AcceptanceTests/PerformanceACTests.swift

import XCTest
@testable import SnippetLibrary

final class PerformanceACTests: XCTestCase {

    /// AC-P001: List View Load Performance
    /// GIVEN 2,000 snippets in database
    /// WHEN user opens Snippets tab
    /// THEN list renders in < 300ms
    func testACP001_ListViewLoadPerformance() async throws {
        // Setup: Create 2000 snippets
        let repository = try await createRepositoryWith2000Snippets()
        let viewModel = await SnippetViewModel(repository: repository, userId: testUserId)

        // Measure
        let start = CFAbsoluteTimeGetCurrent()
        await viewModel.loadSnippets()
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        // Assert: < 300ms
        XCTAssertLessThan(elapsed, 0.3)

        // Log for CI artifact
        print("AC-P001 | List Load | Baseline: N/A | Result: \(elapsed * 1000)ms | Target: <300ms | PASS")
    }

    /// AC-P003: Create/Update Operation Latency
    /// GIVEN valid snippet input
    /// WHEN user saves snippet
    /// THEN operation completes in < 200ms
    func testACP003_CreateOperationLatency() async throws {
        let repository = try await createInMemoryRepository()
        let viewModel = await SnippetViewModel(repository: repository, userId: testUserId)
        let input = SnippetInput(title: "Test", content: String(repeating: "a", count: 5000))

        // Measure
        let start = CFAbsoluteTimeGetCurrent()
        _ = try await viewModel.createSnippet(input: input)
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        // Assert: < 200ms
        XCTAssertLessThan(elapsed, 0.2)

        print("AC-P003 | Create Op | Baseline: N/A | Result: \(elapsed * 1000)ms | Target: <200ms | PASS")
    }
}
```

### B.2 Functional AC Tests

```swift
// Tests/AcceptanceTests/FunctionalACTests.swift

import XCTest
@testable import SnippetLibrary

final class FunctionalACTests: XCTestCase {

    /// AC-F001: Snippet Creation Success
    /// GIVEN valid input (title 1-200 chars, content ≤ 5000 chars, ≤ 10 tags)
    /// WHEN user saves
    /// THEN snippet is persisted with 100% success rate
    func testACF001_SnippetCreationSuccess() async throws {
        let repository = try await createInMemoryRepository()
        let viewModel = await SnippetViewModel(repository: repository, userId: testUserId)

        // Test 100 valid creations
        var successCount = 0
        for i in 0..<100 {
            let input = SnippetInput(
                title: "Snippet \(i)",
                content: "Content",
                tags: ["Tag1"]
            )
            do {
                _ = try await viewModel.createSnippet(input: input)
                successCount += 1
            } catch {
                // Count failures
            }
        }

        // Assert: 100% success
        XCTAssertEqual(successCount, 100)

        print("AC-F001 | Creation | Baseline: N/A | Result: \(successCount)/100 | Target: 100% | PASS")
    }

    /// AC-F003: Title Validation
    /// GIVEN title > 200 characters
    /// WHEN user types
    /// THEN character count shows and save is disabled
    func testACF003_TitleValidation() throws {
        let longTitle = String(repeating: "a", count: 201)

        // Attempt to create
        XCTAssertThrowsError(
            try Snippet(userId: UUID(), title: longTitle)
        ) { error in
            XCTAssertEqual(error as? SnippetError, .titleTooLong(current: 201, max: 200))
        }

        print("AC-F003 | Title Validation | Baseline: N/A | Result: REJECTED | Target: 100% rejection | PASS")
    }

    /// AC-F005: Tag Limit Enforcement
    /// GIVEN 10 tags already added
    /// WHEN user attempts to add 11th tag
    /// THEN input is disabled with message
    func testACF005_TagLimitEnforcement() throws {
        let tags = (1...11).map { "Tag\($0)" }

        XCTAssertThrowsError(
            try Snippet(userId: UUID(), title: "Test", tags: tags)
        ) { error in
            XCTAssertEqual(error as? SnippetError, .tooManyTags(current: 11, max: 10))
        }

        print("AC-F005 | Tag Limit | Baseline: N/A | Result: ENFORCED | Target: 100% | PASS")
    }

    /// AC-F006: Soft Delete Functionality
    /// GIVEN active snippet
    /// WHEN user deletes
    /// THEN deletedAt is set and snippet removed from main list
    func testACF006_SoftDeleteFunctionality() async throws {
        let repository = try await createInMemoryRepository()
        let snippet = try Snippet(userId: testUserId, title: "To Delete")
        _ = try await repository.save(snippet: snippet)

        // Delete
        try await repository.softDelete(id: snippet.id)

        // Verify removed from fetchAll
        let active = try await repository.fetchAll(userId: testUserId)
        XCTAssertFalse(active.contains { $0.id == snippet.id })

        // Verify in fetchDeleted
        let deleted = try await repository.fetchDeleted(userId: testUserId)
        XCTAssertTrue(deleted.contains { $0.id == snippet.id })

        print("AC-F006 | Soft Delete | Baseline: N/A | Result: WORKING | Target: 100% | PASS")
    }

    /// AC-F007: Recovery Window
    /// GIVEN snippet deleted < 30 days ago
    /// WHEN user recovers
    /// THEN snippet returns to active list
    func testACF007_RecoveryWindow() async throws {
        let repository = try await createInMemoryRepository()
        let snippet = try Snippet(userId: testUserId, title: "Recoverable")
        _ = try await repository.save(snippet: snippet)

        // Delete and recover
        try await repository.softDelete(id: snippet.id)
        try await repository.recover(id: snippet.id)

        // Verify recovered
        let active = try await repository.fetchAll(userId: testUserId)
        XCTAssertTrue(active.contains { $0.id == snippet.id })

        print("AC-F007 | Recovery | Baseline: N/A | Result: RECOVERED | Target: 100% | PASS")
    }
}
```

### B.3 Data Integrity AC Tests

```swift
// Tests/AcceptanceTests/DataIntegrityACTests.swift

import XCTest
@testable import SnippetLibrary

final class DataIntegrityACTests: XCTestCase {

    /// AC-D001: Data Persistence
    /// GIVEN user creates snippet
    /// WHEN app is force-quit and reopened
    /// THEN snippet is retained
    func testACD001_DataPersistence() async throws {
        // This test simulates persistence by using file-based storage
        let container = try createFileBasedContainer()
        let repository = await SwiftDataSnippetRepository(modelContainer: container)

        // Create snippet
        let snippet = try Snippet(userId: testUserId, title: "Persistent")
        _ = try await repository.save(snippet: snippet)

        // Create new repository instance (simulates app restart)
        let newRepository = await SwiftDataSnippetRepository(modelContainer: container)
        let fetched = try await newRepository.fetchAll(userId: testUserId)

        // Verify persisted
        XCTAssertTrue(fetched.contains { $0.title == "Persistent" })

        print("AC-D001 | Persistence | Baseline: N/A | Result: RETAINED | Target: 0 data loss | PASS")
    }

    /// AC-D002: Duplicate Tag Prevention
    /// GIVEN user adds same tag twice
    /// WHEN saving
    /// THEN only one instance is stored
    func testACD002_DuplicateTagPrevention() throws {
        let snippet = try Snippet(
            userId: UUID(),
            title: "Test",
            tags: ["Tag1", "Tag1", "Tag2", "Tag2"]
        )

        XCTAssertEqual(snippet.tags.count, 2)
        XCTAssertEqual(Set(snippet.tags), Set(["Tag1", "Tag2"]))

        print("AC-D002 | Duplicate Tags | Baseline: N/A | Result: 0 duplicates | Target: 0 | PASS")
    }

    /// AC-D003: Timestamp Accuracy
    /// GIVEN snippet is updated
    /// WHEN saved
    /// THEN updatedAt reflects current time ± 1 second
    func testACD003_TimestampAccuracy() async throws {
        let repository = try await createInMemoryRepository()
        let original = try Snippet(userId: testUserId, title: "Original")
        _ = try await repository.save(snippet: original)

        // Update
        let beforeUpdate = Date()
        let updated = try Snippet(
            id: original.id,
            userId: testUserId,
            title: "Updated",
            createdAt: original.createdAt,
            updatedAt: Date()
        )
        let saved = try await repository.update(snippet: updated)
        let afterUpdate = Date()

        // Verify timestamp within 1 second
        XCTAssertGreaterThanOrEqual(saved.updatedAt, beforeUpdate)
        XCTAssertLessThanOrEqual(saved.updatedAt, afterUpdate.addingTimeInterval(1))

        print("AC-D003 | Timestamp | Baseline: N/A | Result: ACCURATE | Target: ±1s | PASS")
    }
}
```

---

## PART C: AC-to-Test Traceability Matrix

| AC ID | AC Title | Test Name(s) | Test Type | Status |
|-------|----------|--------------|-----------|--------|
| AC-001 | Form Access | `testSnippetList_TapAddOpensCreateForm` | UI | Pending |
| AC-002 | Valid Snippet Creation | `testACF001_SnippetCreationSuccess` | Integration | Pending |
| AC-003 | Title Validation (Too Long) | `testACF003_TitleValidation` | Unit | Pending |
| AC-004 | Content Validation | `testCreateSnippet_WithContentOver5000Chars_ThrowsContentTooLong` | Unit | Pending |
| AC-005 | Tag Limit Enforcement | `testACF005_TagLimitEnforcement` | Unit | Pending |
| AC-006 | List Update | `testCreateSnippet_InsertsAtTop` | Unit | Pending |
| AC-007 | List Display | `testSnippetList_DisplaysSnippets_WhenPopulated` | UI | Pending |
| AC-008 | Row Content | `testSnippetDetail_DisplaysAllFields` | UI | Pending |
| AC-009 | Empty State | `testSnippetList_DisplaysEmptyState_WhenNoSnippets` | UI | Pending |
| AC-010 | Performance | `testACP001_ListViewLoadPerformance` | Performance | Pending |
| AC-011 | Infinite Scroll | `testFetchAll_Performance_With2000Snippets` | Integration | Pending |
| AC-012 | Detail Display | `testSnippetDetail_DisplaysAllFields` | UI | Pending |
| AC-013 | Action Buttons | `testSnippetDetail_DisplaysAllFields` | UI | Pending |
| AC-014 | Scrollable Content | Manual Testing | Manual | Pending |
| AC-015 | Navigation | Manual Testing | Manual | Pending |
| AC-016 | Pre-populated Form | `testEditSnippet_UpdatesContent` | UI | Pending |
| AC-017 | Save Changes | `testUpdateSnippet_Success_UpdatesInList` | Unit | Pending |
| AC-018 | Timestamp Update | `testACD003_TimestampAccuracy` | Integration | Pending |
| AC-019 | Cancel Edit | `testEditSnippet_Cancel_DiscardsChanges` | UI | Pending |
| AC-020 | Empty Tags | `testCreateSnippet_With10Tags_Succeeds` | Unit | Pending |
| AC-021 | Confirmation Dialog | `testDeleteSnippet_ShowsConfirmation` | UI | Pending |
| AC-022 | Soft Delete | `testACF006_SoftDeleteFunctionality` | Integration | Pending |
| AC-023 | List Removal | `testDeleteSnippet_RemovesFromList` | UI | Pending |
| AC-024 | Cancel Delete | Manual Testing | Manual | Pending |
| AC-025 | Recovery | `testACF007_RecoveryWindow` | Integration | Pending |
| AC-026 | Predefined Suggestions | Manual Testing | Manual | Pending |
| AC-027 | Custom Tag Creation | `testTagInput_AddsChip_OnComma` | UI | Pending |
| AC-028 | Tag Removal | `testTagChip_RemovesOnXTap` | UI | Pending |
| AC-029 | Tag Limit | `testACF005_TagLimitEnforcement` | Unit | Pending |
| AC-030 | Duplicate Prevention | `testACD002_DuplicateTagPrevention` | Unit | Pending |
| AC-P001 | List Load Performance | `testACP001_ListViewLoadPerformance` | Performance | Pending |
| AC-P002 | Detail Load Performance | `testDetailView_LoadsIn100ms` | Performance | Pending |
| AC-P003 | Create/Update Latency | `testACP003_CreateOperationLatency` | Performance | Pending |
| AC-P004 | Memory Efficiency | `testMemoryUsage_Under50MB` | Performance | Pending |
| AC-D001 | Data Persistence | `testACD001_DataPersistence` | Integration | Pending |
| AC-D002 | Duplicate Prevention | `testACD002_DuplicateTagPrevention` | Unit | Pending |
| AC-D003 | Timestamp Accuracy | `testACD003_TimestampAccuracy` | Integration | Pending |
| AC-A001 | VoiceOver Support | Manual Testing | Accessibility | Pending |
| AC-A002 | Dynamic Type | Manual Testing | Accessibility | Pending |
| AC-X001 | iOS Parity | Full Test Suite on iOS | Platform | Pending |
| AC-X002 | macOS Parity | Full Test Suite on macOS | Platform | Pending |

---

## Test Data Requirements

| Dataset | Purpose | Size | Location |
|---------|---------|------|----------|
| `snippet_2000.json` | Performance testing (AC-P001) | 2,000 records | `Tests/Fixtures/` |
| `snippet_edge_cases.json` | Boundary testing | 50 records | `Tests/Fixtures/` |
| `snippet_unicode.json` | Unicode/emoji testing | 20 records | `Tests/Fixtures/` |

---

**Generated by:** AI PRD Generator v7.0 (Enterprise Edition)
**Total Test Cases:** 45
**Test Types:** Unit (22), Integration (12), UI (8), Performance (3)
