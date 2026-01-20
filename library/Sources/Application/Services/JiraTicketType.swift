import Foundation

/// JIRA ticket types
public enum JiraTicketType: String, Sendable, Codable {
    case epic = "Epic"
    case story = "Story"
    case task = "Task"
    case subTask = "Sub-task"
    case bug = "Bug"
}
