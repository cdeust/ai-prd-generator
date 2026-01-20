import Foundation

/// Individual test case
/// Following Single Responsibility Principle - represents test case
public struct TestCase: Identifiable, Sendable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let steps: [TestStep]
    public let expectedResult: String
    public let priority: TestPriority
    public let category: TestCategory

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        steps: [TestStep],
        expectedResult: String,
        priority: TestPriority = .medium,
        category: TestCategory
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.steps = steps
        self.expectedResult = expectedResult
        self.priority = priority
        self.category = category
    }
}
