import Foundation

/// Represents a sub-task within a JIRA ticket
public struct JiraSubTask: Sendable {
    public let title: String
    public let description: String
    public let storyPoints: Int?

    public init(title: String, description: String, storyPoints: Int? = nil) {
        self.title = title
        self.description = description
        self.storyPoints = storyPoints
    }
}
