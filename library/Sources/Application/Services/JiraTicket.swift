import Foundation

/// Represents a JIRA ticket with comprehensive fields for accurate project management
public struct JiraTicket: Sendable {
    /// Ticket title - concise summary of the work
    public let title: String

    /// Detailed description explaining the "why" and "what"
    public let description: String

    /// Ticket type: Epic, Story, Task, Sub-task, Bug
    public let type: JiraTicketType

    /// Priority level: Critical, High, Medium, Low
    public let priority: JiraPriority

    /// Story points estimate (1, 2, 3, 5, 8, 13, 21)
    public let storyPoints: Int?

    /// Labels for categorization (e.g., "backend", "frontend", "api")
    public let labels: [String]

    /// Component the ticket belongs to
    public let component: String?

    /// Epic key this ticket belongs to (for Stories/Tasks)
    public let epicKey: String?

    /// Specific acceptance criteria for this ticket
    public let acceptanceCriteria: [String]

    /// Sub-tasks for breaking down larger work
    public let subTasks: [JiraSubTask]

    /// Technical notes for implementers
    public let technicalNotes: String?

    /// Dependencies on other tickets
    public let dependencies: [String]

    public init(
        title: String,
        description: String,
        type: JiraTicketType = .story,
        priority: JiraPriority = .medium,
        storyPoints: Int? = nil,
        labels: [String] = [],
        component: String? = nil,
        epicKey: String? = nil,
        acceptanceCriteria: [String] = [],
        subTasks: [JiraSubTask] = [],
        technicalNotes: String? = nil,
        dependencies: [String] = []
    ) {
        self.title = title
        self.description = description
        self.type = type
        self.priority = priority
        self.storyPoints = storyPoints
        self.labels = labels
        self.component = component
        self.epicKey = epicKey
        self.acceptanceCriteria = acceptanceCriteria
        self.subTasks = subTasks
        self.technicalNotes = technicalNotes
        self.dependencies = dependencies
    }
}
