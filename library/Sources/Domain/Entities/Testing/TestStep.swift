import Foundation

/// Individual test step
/// Following Single Responsibility Principle - represents test step
public struct TestStep: Identifiable, Sendable, Codable {
    public let id: UUID
    public let stepNumber: Int
    public let action: String
    public let expectedOutcome: String?

    public init(
        id: UUID = UUID(),
        stepNumber: Int,
        action: String,
        expectedOutcome: String? = nil
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.action = action
        self.expectedOutcome = expectedOutcome
    }
}
