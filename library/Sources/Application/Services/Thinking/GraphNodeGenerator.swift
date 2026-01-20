import Foundation
import Domain

/// Generates thought nodes for graph-based reasoning
/// Single Responsibility: Create interconnected thought nodes
public struct GraphNodeGenerator: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Generate next valuable thought node
    public func generate(
        currentGraph: ThoughtGraph,
        context: String,
        iteration: Int
    ) async throws -> ContextNode {
        let prompt = buildNodePrompt(
            graph: currentGraph,
            context: context,
            iteration: iteration
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.7
        )

        return parseNode(from: response)
    }

    // MARK: - Private Methods

    private func buildNodePrompt(
        graph: ThoughtGraph,
        context: String,
        iteration: Int
    ) -> String {
        let existingInsights = graph.nodes
            .filter { $0.type == .inference }
            .map { $0.content }
            .joined(separator: "\n- ")

        return """
        Given the following problem and existing reasoning graph:

        <problem>
        \(graph.problem)
        </problem>

        <existing_insights>
        \(existingInsights.isEmpty ? "None yet" : "- \(existingInsights)")
        </existing_insights>

        <context>
        \(context)
        </context>

        Generate the next valuable thought node. This can be:
        - A new perspective or angle
        - A connecting insight between existing ideas
        - A refinement or challenge to previous thoughts
        - A synthesis of multiple threads

        Provide:
        NODE_TYPE: [question|assumption|inference|evidence]
        CONTENT: [the actual thought/insight]
        CONFIDENCE: [0.0-1.0]
        BUILDS_ON: [which existing nodes this relates to, if any]
        """
    }

    private func parseNode(from response: String) -> ContextNode {
        let lines = response.components(separatedBy: "\n")
        var nodeTypeValue: ContextNodeType = .inference
        var content = ""
        var confidence = 0.7
        var buildsOn: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.starts(with: "NODE_TYPE:") {
                nodeTypeValue = parseNodeType(from: trimmed)
            } else if trimmed.starts(with: "CONTENT:") {
                content = extractValue(from: trimmed, prefix: "CONTENT:")
            } else if trimmed.starts(with: "CONFIDENCE:") {
                confidence = parseConfidence(from: trimmed)
            } else if trimmed.starts(with: "BUILDS_ON:") {
                buildsOn = parseBuildsOn(from: trimmed)
            }
        }

        return ContextNode(
            id: UUID(),
            type: nodeTypeValue,
            content: content.isEmpty ? "Generated insight" : content,
            confidence: confidence,
            metadata: buildsOn.isEmpty ? [:] : ["builds_on": buildsOn.joined(separator: ",")]
        )
    }

    private func parseNodeType(from line: String) -> ContextNodeType {
        let typeStr = extractValue(from: line, prefix: "NODE_TYPE:").lowercased()

        switch typeStr {
        case "question": return .question
        case "assumption": return .assumption
        case "inference": return .inference
        case "evidence": return .evidence
        default: return .inference
        }
    }

    private func parseConfidence(from line: String) -> Double {
        let confStr = extractValue(from: line, prefix: "CONFIDENCE:")
        return Double(confStr) ?? 0.7
    }

    private func parseBuildsOn(from line: String) -> [String] {
        let buildsStr = extractValue(from: line, prefix: "BUILDS_ON:")
        return buildsStr.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func extractValue(from line: String, prefix: String) -> String {
        line.replacingOccurrences(of: prefix, with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
