import Foundation

/// Test suite entity for generated tests
/// Following Single Responsibility Principle - represents test suite
public struct TestSuite: Identifiable, Sendable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let tests: [TestCase]
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        tests: [TestCase],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.tests = tests
        self.createdAt = createdAt
    }

    public var totalTests: Int {
        tests.count
    }

    public var criticalTests: Int {
        tests.filter { $0.priority == .critical }.count
    }
}
