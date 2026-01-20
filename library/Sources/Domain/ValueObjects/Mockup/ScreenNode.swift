import Foundation

/// Node representing a screen in a user flow
public struct ScreenNode: Sendable, Codable, Equatable, Identifiable {
    /// Unique identifier
    public let id: UUID

    /// Screen name or title
    public let name: String

    /// Screen description
    public let description: String?

    /// Screen type
    public let type: ScreenType

    /// Reference to mockup analysis result
    public let mockupId: UUID?

    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        type: ScreenType,
        mockupId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.mockupId = mockupId
    }
}
