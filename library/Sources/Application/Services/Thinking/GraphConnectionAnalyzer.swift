import Foundation
import Domain

/// Analyzes and identifies semantic connections between thought nodes
/// Single Responsibility: Build graph edges based on relationships
public struct GraphConnectionAnalyzer: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Identify connections between new node and existing nodes
    public func identifyConnections(
        newNode: ContextNode,
        existingNodes: [ContextNode],
        context: String
    ) async throws -> [ContextEdge] {
        guard existingNodes.count > 1 else { return [] }

        let prompt = buildConnectionPrompt(
            newNode: newNode,
            existingNodes: existingNodes,
            context: context
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.3
        )

        return parseConnections(
            response: response,
            newNodeId: newNode.id,
            existingNodes: existingNodes
        )
    }

    // MARK: - Private Methods

    private func buildConnectionPrompt(
        newNode: ContextNode,
        existingNodes: [ContextNode],
        context: String
    ) -> String {
        let nodesList = existingNodes.enumerated()
            .map { "\($0.offset): \($0.element.content)" }
            .joined(separator: "\n")

        return """
        Identify semantic connections between this new thought:

        <new_thought>
        \(newNode.content)
        </new_thought>

        And existing thoughts:
        \(nodesList)

        For each meaningful connection, provide:
        CONNECTED_TO: [node number]
        RELATIONSHIP: [supports|contradicts|refines|depends_on|synthesizes]
        STRENGTH: [0.0-1.0]

        Only include strong connections (strength > 0.5).
        """
    }

    private func parseConnections(
        response: String,
        newNodeId: UUID,
        existingNodes: [ContextNode]
    ) -> [ContextEdge] {
        let lines = response.components(separatedBy: "\n")
        var connections: [ContextEdge] = []
        var currentConnection = ConnectionComponents()

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.starts(with: "CONNECTED_TO:") {
                currentConnection.index = parseIndex(from: trimmed)
            } else if trimmed.starts(with: "RELATIONSHIP:") {
                currentConnection.edgeType = parseEdgeType(from: trimmed)
            } else if trimmed.starts(with: "STRENGTH:") {
                currentConnection.strength = parseStrength(from: trimmed)

                if let edge = buildEdge(
                    from: currentConnection,
                    newNodeId: newNodeId,
                    existingNodes: existingNodes
                ) {
                    connections.append(edge)
                }

                currentConnection = ConnectionComponents()
            }
        }

        return connections
    }

    private func parseIndex(from line: String) -> Int? {
        let numStr = extractValue(from: line, prefix: "CONNECTED_TO:")
        return Int(numStr)
    }

    private func parseEdgeType(from line: String) -> ContextRelationship? {
        let relStr = extractValue(from: line, prefix: "RELATIONSHIP:").lowercased()

        switch relStr {
        case "supports": return .supports
        case "contradicts": return .contradicts
        case "refines": return .refines
        case "depends_on": return .dependsOn
        case "synthesizes": return .synthesizes
        default: return nil
        }
    }

    private func parseStrength(from line: String) -> Double? {
        let strengthStr = extractValue(from: line, prefix: "STRENGTH:")
        return Double(strengthStr)
    }

    private func extractValue(from line: String, prefix: String) -> String {
        line.replacingOccurrences(of: prefix, with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private func buildEdge(
        from components: ConnectionComponents,
        newNodeId: UUID,
        existingNodes: [ContextNode]
    ) -> ContextEdge? {
        guard let index = components.index,
              let edgeType = components.edgeType,
              let strength = components.strength,
              index < existingNodes.count else {
            return nil
        }

        return ContextEdge(
            id: UUID(),
            source: newNodeId,
            target: existingNodes[index].id,
            relationship: edgeType,
            strength: strength,
            timestamp: Date()
        )
    }
}

