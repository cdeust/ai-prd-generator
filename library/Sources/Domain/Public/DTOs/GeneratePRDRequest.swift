import Foundation

/// Public request to generate a PRD
/// Public DTO for PRD generation requests
public struct GeneratePRDRequest: Sendable {
    public let title: String
    public let description: String
    public let priority: Priority
    public let mockups: [MockupInput]?
    public let codebaseId: UUID?

    public init(
        title: String,
        description: String,
        priority: Priority = .medium,
        mockups: [MockupInput]? = nil,
        codebaseId: UUID? = nil
    ) {
        self.title = title
        self.description = description
        self.priority = priority
        self.mockups = mockups
        self.codebaseId = codebaseId
    }
}
