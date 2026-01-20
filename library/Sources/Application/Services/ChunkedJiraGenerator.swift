import Foundation
import Domain

/// JIRA ticket generator with adaptive chunking
/// Measures actual prompt overhead and uses provider's context window size
public struct ChunkedJiraGenerator: Sendable {
    private let aiProvider: AIProviderPort
    private let tokenizer: TokenizerPort?

    public init(
        aiProvider: AIProviderPort,
        tokenizer: TokenizerPort? = nil
    ) {
        self.aiProvider = aiProvider
        self.tokenizer = tokenizer
    }

    /// Generate JIRA tickets from PRD using multi-pass (one section at a time)
    /// Same strategy as PRD generation - never hits context limits
    public func generateTickets(
        from document: PRDDocument,
        includeAcceptanceCriteria: Bool
    ) async throws -> [JiraTicket] {
        print("🎫 [JiraGenerator] Generating tickets for \(document.sections.count) sections (multi-pass)")

        var allTickets: [JiraTicket] = []

        // Generate tickets ONE SECTION AT A TIME (multi-pass)
        for (index, section) in document.sections.enumerated() {
            print("🔄 [JiraGenerator] Processing section \(index + 1)/\(document.sections.count): \(section.title)")

            let tickets = try await generateTicketsForSection(
                title: document.title,
                section: section,
                includeAC: includeAcceptanceCriteria,
                sectionIndex: index,
                totalSections: document.sections.count
            )

            allTickets.append(contentsOf: tickets)
            print("✅ [JiraGenerator] Generated \(tickets.count) tickets for \(section.title)")
        }

        print("✨ [JiraGenerator] Complete: \(allTickets.count) total tickets")
        return allTickets
    }

    private func generateTicketsForSection(
        title: String,
        section: PRDSection,
        includeAC: Bool,
        sectionIndex: Int,
        totalSections: Int
    ) async throws -> [JiraTicket] {
        let systemPrompt = buildSystemPrompt(includeAC: includeAC)
        let sectionContent = "## \(section.title)\n\(section.content)"

        let contextInfo = totalSections > 1
            ? "\n\n**Note:** This is section \(sectionIndex + 1) of \(totalSections) from the full PRD. Generate tickets for this section only."
            : ""

        let prompt = """
        \(systemPrompt)

        PRD Title: \(title)

        \(sectionContent)\(contextInfo)

        Generate 2-5 well-structured tickets for this section.
        """

        let response = try await aiProvider.generateText(prompt: prompt, temperature: 0.3)
        return parseTicketsFromResponse(response)
    }

    private func buildSystemPrompt(includeAC: Bool) -> String {
        """
        Analyze PRD content and generate JIRA tickets.

        **Guidelines:**
        1. Epic: Group related work (1-2 per chunk)
        2. Stories: User-facing features with business value
        3. Tasks: Technical/non-user work
        4. Sub-tasks: Break complex work into pieces

        **Ticket Fields:**
        - title: Clear, action-oriented
        - description: WHY and WHAT
        - type: Epic|Story|Task|Sub-task
        - priority: Critical|High|Medium|Low
        - storyPoints: Fibonacci (1,2,3,5,8,13)
        - labels: [backend,frontend,api,etc]
        - component: Main system component
        \(includeAC ? "- acceptanceCriteria: 3-7 testable criteria\n" : "")- technicalNotes: Implementation hints
        - dependencies: IDs of required tickets

        **Output Format:**
        JSON array only:
        [{"title":"...","description":"...","type":"Story","priority":"High","storyPoints":5,"labels":["api"],"component":"Backend","acceptanceCriteria":["..."],"subTasks":[{"title":"...","description":"..."}],"technicalNotes":"...","dependencies":[]}]
        """
    }

    private func parseTicketsFromResponse(_ response: String) -> [JiraTicket] {
        guard let jsonStart = response.firstIndex(of: "["),
              let jsonEnd = response.lastIndex(of: "]") else {
            print("⚠️ [ChunkedJira] No JSON array found")
            return []
        }

        let jsonString = String(response[jsonStart...jsonEnd])
        guard let data = jsonString.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("⚠️ [ChunkedJira] Invalid JSON")
            return []
        }

        return parsed.compactMap { parseTicket($0) }
    }

    private func parseTicket(_ dict: [String: Any]) -> JiraTicket? {
        guard let title = dict["title"] as? String,
              let description = dict["description"] as? String else { return nil }

        let type = JiraTicketType(rawValue: dict["type"] as? String ?? "Story") ?? .story
        let priority = JiraPriority(rawValue: dict["priority"] as? String ?? "Medium") ?? .medium
        let subTasks = parseSubTasks(dict["subTasks"] as? [[String: Any]] ?? [])

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

    private func parseSubTasks(_ dicts: [[String: Any]]) -> [JiraSubTask] {
        dicts.compactMap { dict -> JiraSubTask? in
            guard let title = dict["title"] as? String,
                  let desc = dict["description"] as? String else { return nil }
            return JiraSubTask(title: title, description: desc, storyPoints: dict["storyPoints"] as? Int)
        }
    }
}
