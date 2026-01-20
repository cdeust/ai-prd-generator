import Foundation
import Domain

/// AI-powered service for generating detailed JIRA tickets from PRD content
/// Uses AI to analyze requirements and generate accurate, well-structured tickets
public struct JiraTicketGeneratorService: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Generate JIRA tickets from PRD document using AI analysis
    public func generateTickets(
        from document: PRDDocument,
        includeAcceptanceCriteria: Bool
    ) async throws -> [JiraTicket] {
        let prompt = buildPrompt(document: document, includeAC: includeAcceptanceCriteria)
        let response = try await aiProvider.generateText(prompt: prompt, temperature: 0.3)
        return parseTicketsFromResponse(response)
    }

    private func buildPrompt(document: PRDDocument, includeAC: Bool) -> String {
        let sectionsContent = document.sections.map { "## \($0.title)\n\($0.content)" }
            .joined(separator: "\n\n")

        return """
        Analyze the following PRD document and generate detailed JIRA tickets.

        PRD Title: \(document.title)

        \(sectionsContent)

        \(ticketGuidelines)

        \(ticketFields(includeAC: includeAC))

        \(jsonFormatExample)

        Generate 5-15 well-structured tickets that comprehensively cover the PRD requirements.
        """
    }

    private var ticketGuidelines: String {
        """
        Generate JIRA tickets following these guidelines:
        1. **Epic Structure**: Create 1-3 Epics that group related work
        2. **Stories**: Create user-facing stories with clear business value
        3. **Tasks**: Create technical tasks for infrastructure or non-user-facing work
        4. **Sub-tasks**: Break down complex work into smaller, manageable pieces
        """
    }

    private func ticketFields(includeAC: Bool) -> String {
        var fields = """
        For each ticket, provide:
        - **title**: Clear, action-oriented title
        - **description**: Detailed explanation of WHY and WHAT
        - **type**: Epic, Story, Task, or Sub-task
        - **priority**: Critical, High, Medium, or Low
        - **storyPoints**: Fibonacci estimate (1, 2, 3, 5, 8, 13)
        - **labels**: Relevant tags (backend, frontend, api, etc.)
        - **component**: Main system component affected
        """
        if includeAC { fields += "\n- **acceptanceCriteria**: 3-7 specific, testable criteria" }
        fields += """

        - **technicalNotes**: Implementation hints for developers
        - **dependencies**: IDs of tickets that must be completed first
        """
        return fields
    }

    private var jsonFormatExample: String {
        """
        Respond ONLY with a JSON array:
        [{"title":"...","description":"...","type":"Story|Task|Epic","priority":"Critical|High|Medium|Low","storyPoints":3,"labels":["backend"],"component":"Auth","acceptanceCriteria":["..."],"subTasks":[{"title":"...","description":"..."}],"technicalNotes":"...","dependencies":[]}]
        """
    }

    private func parseTicketsFromResponse(_ response: String) -> [JiraTicket] {
        guard let jsonStart = response.firstIndex(of: "["),
              let jsonEnd = response.lastIndex(of: "]") else {
            print("⚠️ [JiraGenerator] Could not find JSON array in response")
            return []
        }

        let jsonString = String(response[jsonStart...jsonEnd])
        guard let data = jsonString.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("⚠️ [JiraGenerator] Invalid JSON in response")
            return []
        }

        return parsed.compactMap { parseTicketFromDictionary($0) }
    }

    private func parseTicketFromDictionary(_ dict: [String: Any]) -> JiraTicket? {
        guard let title = dict["title"] as? String,
              let description = dict["description"] as? String else { return nil }

        let type = JiraTicketType(rawValue: dict["type"] as? String ?? "Story") ?? .story
        let priority = JiraPriority(rawValue: dict["priority"] as? String ?? "Medium") ?? .medium
        let subTasks = parseSubTasks(from: dict["subTasks"] as? [[String: Any]] ?? [])

        return JiraTicket(
            title: title,
            description: description,
            type: type,
            priority: priority,
            storyPoints: dict["storyPoints"] as? Int,
            labels: dict["labels"] as? [String] ?? [],
            component: dict["component"] as? String,
            epicKey: dict["epicKey"] as? String,
            acceptanceCriteria: dict["acceptanceCriteria"] as? [String] ?? [],
            subTasks: subTasks,
            technicalNotes: dict["technicalNotes"] as? String,
            dependencies: dict["dependencies"] as? [String] ?? []
        )
    }

    private func parseSubTasks(from dicts: [[String: Any]]) -> [JiraSubTask] {
        dicts.compactMap { subDict -> JiraSubTask? in
            guard let title = subDict["title"] as? String,
                  let desc = subDict["description"] as? String else { return nil }
            return JiraSubTask(title: title, description: desc, storyPoints: subDict["storyPoints"] as? Int)
        }
    }
}
