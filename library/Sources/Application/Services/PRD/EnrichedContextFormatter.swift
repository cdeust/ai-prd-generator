import Foundation
import Domain

/// Formats enriched context for PRD section generation
/// Extracted from EnrichedContextBuilder to maintain file size limits
struct EnrichedContextFormatter: Sendable {
    func formatReasoningOnly(_ reasoning: ReasoningPlan?) -> String {
        guard let reasoning = reasoning else { return "" }

        var result = """
        # Analysis
        Confidence: \(String(format: "%.2f", reasoning.confidence))

        """

        if !reasoning.steps.isEmpty {
            result += """
            Key Steps:
            \(reasoning.steps.joined(separator: "\n"))

            """
        }

        if !reasoning.keyDecisions.isEmpty {
            result += """
            Important Decisions:
            \(reasoning.keyDecisions.joined(separator: "\n"))
            """
        }

        return result
    }

    func formatTechnicalDecisions(_ reasoning: ReasoningPlan) -> String {
        guard !reasoning.keyDecisions.isEmpty else { return "" }

        return """
        # Technical Decisions
        \(reasoning.keyDecisions.joined(separator: "\n"))
        """
    }

    func formatUserFocusedReasoning(_ reasoning: ReasoningPlan?) -> String {
        guard let reasoning = reasoning else { return "" }

        let userSteps = reasoning.steps.filter { step in
            step.lowercased().contains("user") ||
            step.lowercased().contains("persona") ||
            step.lowercased().contains("workflow") ||
            step.lowercased().contains("experience")
        }

        guard !userSteps.isEmpty else {
            return formatReasoningOnly(reasoning)
        }

        return """
        # User-Focused Analysis
        Confidence: \(String(format: "%.2f", reasoning.confidence))

        Key User Insights:
        \(userSteps.joined(separator: "\n"))
        """
    }

    func formatCodeSummary(_ code: RAGSearchResults, maxChunks: Int) -> String {
        """
        # Codebase Reference
        \(code.relevantChunks.prefix(maxChunks).joined(separator: "\n\n"))
        """
    }

    func formatCodeDetailed(_ code: RAGSearchResults, maxChunks: Int) -> String {
        """
        # Codebase Analysis
        Files: \(code.relevantFiles.count)
        Relevance: \(String(format: "%.2f", code.averageRelevanceScore))

        Relevant Code Patterns:
        \(code.relevantChunks.prefix(maxChunks).joined(separator: "\n\n"))
        """
    }

    func formatVisionResults(_ visionResults: [MockupAnalysisResult]?) -> String {
        guard let results = visionResults, !results.isEmpty else { return "" }
        var output = "# Mockup Analysis\n\n"
        for (index, result) in results.prefix(3).enumerated() {
            output += formatScreenHeader(index: index, result: result)
            output += formatComponents(result.components)
            output += formatDataRequirements(result.dataRequirements)
            output += formatInteractions(result.interactions)
        }
        return output
    }

    private func formatScreenHeader(index: Int, result: MockupAnalysisResult) -> String {
        var header = "## Screen \(index + 1)"
        if let name = result.screenName { header += ": \(name)" }
        header += "\n"
        if let desc = result.screenDescription { header += "Description: \(desc)\n\n" }
        return header
    }

    private func formatComponents(_ components: [UIComponent]) -> String {
        guard !components.isEmpty else { return "" }
        var output = "Components:\n"
        for comp in components.prefix(10) {
            output += "- \(comp.type.rawValue)\(comp.label.map { ": \($0)" } ?? "")\n"
        }
        return output + "\n"
    }

    private func formatDataRequirements(_ requirements: [InferredDataRequirement]) -> String {
        guard !requirements.isEmpty else { return "" }
        var output = "Data Requirements:\n"
        for req in requirements.prefix(5) {
            output += "- \(req.fieldName) (\(req.dataType.rawValue))\(req.isRequired ? " [required]" : "")\n"
        }
        return output + "\n"
    }

    private func formatInteractions(_ interactions: [Interaction]) -> String {
        guard !interactions.isEmpty else { return "" }
        var output = "Interactions:\n"
        for interaction in interactions.prefix(5) {
            output += "- \(interaction.trigger.rawValue): \(interaction.description ?? "")\n"
        }
        return output + "\n"
    }

    func formatVisionSummary(_ visionResults: [MockupAnalysisResult]?) -> String {
        guard let results = visionResults, !results.isEmpty else { return "" }

        var componentTypes: Set<String> = []
        var dataFields: Set<String> = []

        for result in results {
            for component in result.components {
                componentTypes.insert(component.type.rawValue)
            }
            for req in result.dataRequirements {
                dataFields.insert(req.fieldName)
            }
        }

        return """
        # UI Overview
        Screens analyzed: \(results.count)
        Component types: \(componentTypes.sorted().joined(separator: ", "))
        Data fields identified: \(dataFields.sorted().prefix(10).joined(separator: ", "))
        """
    }

    func extractSteps(from result: ThinkingResult) -> [String] {
        result.conclusion.components(separatedBy: "\n")
            .filter { $0.contains("Step") || $0.contains(".") }
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func extractDecisions(from result: ThinkingResult) -> [String] {
        result.conclusion.components(separatedBy: "\n")
            .filter {
                $0.contains("decision") ||
                $0.contains("choose") ||
                $0.contains("should")
            }
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
