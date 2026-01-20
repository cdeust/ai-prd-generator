import Foundation
import Domain

/// Formats JIRA tickets into markdown for PRD output
/// Following Single Responsibility Principle - ONE job: format tickets as markdown
public struct JiraTicketFormatter: Sendable {

    public init() {}

    /// Format JIRA tickets as markdown section
    public func formatTicketsAsMarkdown(_ tickets: [JiraTicket]) -> String {
        guard !tickets.isEmpty else {
            return formatEmptyTicketsSection()
        }

        var output = buildHeader()

        // Group tickets by type for better organization
        let epics = tickets.filter { $0.type == .epic }
        let stories = tickets.filter { $0.type == .story }
        let tasks = tickets.filter { $0.type == .task }

        // Format epics first
        if !epics.isEmpty {
            output += "\n### Epics\n\n"
            for (index, ticket) in epics.enumerated() {
                output += formatTicket(ticket: ticket, prefix: "EPIC", number: index + 1)
            }
        }

        // Format stories
        if !stories.isEmpty {
            output += "\n### User Stories\n\n"
            for (index, ticket) in stories.enumerated() {
                output += formatTicket(ticket: ticket, prefix: "STORY", number: index + 1)
            }
        }

        // Format tasks
        if !tasks.isEmpty {
            output += "\n### Technical Tasks\n\n"
            for (index, ticket) in tasks.enumerated() {
                output += formatTicket(ticket: ticket, prefix: "TASK", number: index + 1)
            }
        }

        output += formatSummary(tickets: tickets)
        return output
    }

    /// Legacy method for backward compatibility with old generation flow
    public func generateJiraTickets(
        from document: PRDDocument,
        includeAcceptanceCriteria: Bool
    ) -> String {
        // This will be replaced by AI-generated tickets
        // For now, extract basic tickets from document and format them
        let tickets = extractBasicTicketsFromSections(document.sections)
        return formatTicketsAsMarkdown(tickets)
    }

    private func buildHeader() -> String {
        """

        ---

        ## JIRA Tickets

        The following JIRA tickets have been generated from this PRD. Each ticket includes estimated story points, priority, and specific acceptance criteria.

        """
    }

    private func formatEmptyTicketsSection() -> String {
        """

        ---

        ## JIRA Tickets

        No specific JIRA tickets could be generated from this PRD. Please review the requirements and create tickets manually.

        """
    }

    private func formatTicket(ticket: JiraTicket, prefix: String, number: Int) -> String {
        var output = formatTicketHeader(ticket: ticket, prefix: prefix, number: number)
        output += formatTicketMetadata(ticket: ticket)
        output += "\n**Description:**\n\(ticket.description)\n\n"
        output += formatAcceptanceCriteria(ticket.acceptanceCriteria)
        output += formatSubTasks(ticket.subTasks)
        if let notes = ticket.technicalNotes, !notes.isEmpty {
            output += "**Technical Notes:**\n> \(notes)\n\n"
        }
        if !ticket.dependencies.isEmpty {
            output += "**Dependencies:** \(ticket.dependencies.joined(separator: ", "))\n\n"
        }
        output += "---\n\n"
        return output
    }

    private func formatTicketHeader(ticket: JiraTicket, prefix: String, number: Int) -> String {
        """
        #### \(prefix)-\(number): \(ticket.title)

        | Field | Value |
        |-------|-------|
        | **Type** | \(ticket.type.rawValue) |
        | **Priority** | \(priorityEmoji(ticket.priority)) \(ticket.priority.rawValue) |
        """
    }

    private func formatTicketMetadata(ticket: JiraTicket) -> String {
        var output = ""
        if let points = ticket.storyPoints { output += "| **Story Points** | \(points) |\n" }
        if let component = ticket.component { output += "| **Component** | \(component) |\n" }
        if !ticket.labels.isEmpty { output += "| **Labels** | \(ticket.labels.joined(separator: ", ")) |\n" }
        if let epicKey = ticket.epicKey { output += "| **Epic** | \(epicKey) |\n" }
        return output
    }

    private func formatAcceptanceCriteria(_ criteria: [String]) -> String {
        guard !criteria.isEmpty else { return "" }
        return "**Acceptance Criteria:**\n" + criteria.map { "- [ ] \($0)" }.joined(separator: "\n") + "\n\n"
    }

    private func formatSubTasks(_ subTasks: [JiraSubTask]) -> String {
        guard !subTasks.isEmpty else { return "" }
        var output = "**Sub-tasks:**\n"
        for (index, subTask) in subTasks.enumerated() {
            let points = subTask.storyPoints.map { " (\($0) pts)" } ?? ""
            output += "\(index + 1). \(subTask.title)\(points)\n"
            if !subTask.description.isEmpty { output += "   _\(subTask.description)_\n" }
        }
        return output + "\n"
    }

    private func priorityEmoji(_ priority: JiraPriority) -> String {
        switch priority {
        case .critical: return "🔴"
        case .high: return "🟠"
        case .medium: return "🟡"
        case .low: return "🟢"
        }
    }

    private func formatSummary(tickets: [JiraTicket]) -> String {
        let totalPoints = tickets.compactMap { $0.storyPoints }.reduce(0, +)
        let subTaskPoints = tickets.flatMap { $0.subTasks }.compactMap { $0.storyPoints }.reduce(0, +)

        let criticalCount = tickets.filter { $0.priority == .critical }.count
        let highCount = tickets.filter { $0.priority == .high }.count

        return """

        ### Summary

        | Metric | Value |
        |--------|-------|
        | Total Tickets | \(tickets.count) |
        | Total Story Points | \(totalPoints + subTaskPoints) |
        | Critical Priority | \(criticalCount) |
        | High Priority | \(highCount) |

        """
    }

    /// Basic ticket extraction for legacy/fallback mode
    private func extractBasicTicketsFromSections(_ sections: [PRDSection]) -> [JiraTicket] {
        var tickets: [JiraTicket] = []

        for section in sections {
            switch section.type {
            case .requirements:
                tickets.append(contentsOf: extractRequirementTickets(from: section))
            case .userStories:
                tickets.append(contentsOf: extractUserStoryTickets(from: section))
            case .technicalSpecification:
                tickets.append(contentsOf: extractTechnicalTickets(from: section))
            default:
                continue
            }
        }

        return tickets.isEmpty ? [createDefaultEpic()] : tickets
    }

    private func extractRequirementTickets(from section: PRDSection) -> [JiraTicket] {
        let lines = section.content.components(separatedBy: "\n")
        var tickets: [JiraTicket] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
                let requirement = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                if !requirement.isEmpty && requirement.count > 10 {
                    tickets.append(JiraTicket(
                        title: "Implement: \(requirement.prefix(80))",
                        description: requirement,
                        type: .story,
                        priority: .medium,
                        acceptanceCriteria: [
                            "Requirement is fully implemented",
                            "All edge cases are handled",
                            "Unit tests cover the implementation"
                        ]
                    ))
                }
            }
        }

        return tickets
    }

    private func extractUserStoryTickets(from section: PRDSection) -> [JiraTicket] {
        let lines = section.content.components(separatedBy: "\n")
        var tickets: [JiraTicket] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
            if trimmed.hasPrefix("as a") || trimmed.hasPrefix("as an") {
                tickets.append(JiraTicket(
                    title: line.trimmingCharacters(in: .whitespaces),
                    description: line.trimmingCharacters(in: .whitespaces),
                    type: .story,
                    priority: .medium,
                    acceptanceCriteria: [
                        "User story is fully implemented",
                        "User can complete the described action",
                        "Edge cases are handled gracefully"
                    ]
                ))
            }
        }

        return tickets
    }

    private func extractTechnicalTickets(from section: PRDSection) -> [JiraTicket] {
        let lines = section.content.components(separatedBy: "\n")
        var tickets: [JiraTicket] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if (trimmed.hasPrefix("###") || trimmed.hasPrefix("####")) && !trimmed.contains("Table") {
                let title = trimmed
                    .replacingOccurrences(of: "#", with: "")
                    .trimmingCharacters(in: .whitespaces)

                if !title.isEmpty {
                    tickets.append(JiraTicket(
                        title: title,
                        description: "Technical implementation for: \(title)",
                        type: .task,
                        priority: .medium,
                        labels: ["technical"],
                        acceptanceCriteria: [
                            "Implementation is complete",
                            "Code follows architecture guidelines",
                            "Technical documentation is updated"
                        ]
                    ))
                }
            }
        }

        return tickets
    }

    private func createDefaultEpic() -> JiraTicket {
        JiraTicket(
            title: "Implement PRD Requirements",
            description: "Epic containing all requirements from this PRD document.",
            type: .epic,
            priority: .high,
            storyPoints: 13,
            acceptanceCriteria: [
                "All functional requirements are implemented",
                "All technical requirements are met",
                "System passes acceptance testing",
                "Documentation is complete"
            ]
        )
    }
}
