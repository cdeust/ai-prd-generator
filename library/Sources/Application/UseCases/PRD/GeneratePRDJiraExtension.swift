import Foundation
import Domain

/// Extension for JIRA ticket generation functionality
extension GeneratePRDUseCase {

    func generateJiraSection(
        request: PRDRequest,
        sections: [PRDSection],
        onChunk: @escaping (String) async throws -> Void
    ) async throws -> PRDSection {
        let includeAC = request.metadata["includeAcceptanceCriteria"] == "true"
        let tempDoc = PRDDocument(
            userId: request.userId,
            title: request.title,
            sections: sections,
            metadata: DocumentMetadata(
                author: "",
                projectName: "",
                aiProvider: "",
                codebaseId: nil
            )
        )

        print("🎫 Generating JIRA tickets with AI...")
        try await onChunk("\n\n---\n\n## Generating JIRA Tickets...\n\n")

        let tickets = try await jiraGenerator.generateTickets(
            from: tempDoc,
            includeAcceptanceCriteria: includeAC
        )
        let jiraContent = JiraTicketFormatter().formatTicketsAsMarkdown(tickets)

        print("✅ Generated \(tickets.count) AI-powered JIRA tickets")
        try await onChunk(jiraContent)

        return PRDSection(
            type: .deployment,
            title: "JIRA Tickets",
            content: jiraContent,
            order: sections.count
        )
    }
}
