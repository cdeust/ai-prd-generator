import Foundation
import Domain

/// Graph enrichment for retrieved chunks
/// Following Single Responsibility: Adds chunks to context graph with relationships
public actor GraphEnricher {
    private let contextTracker: ContextGraphTracker

    public init(contextTracker: ContextGraphTracker) {
        self.contextTracker = contextTracker
    }

    /// Enrich chunks with graph relationships
    public func enrichWithGraph(
        chunks: [RankedChunk],
        query: String,
        currentContext: String
    ) async -> [RankedChunk] {
        var enriched: [RankedChunk] = []

        for chunk in chunks {
            let node = createContextNode(from: chunk)
            await contextTracker.addNode(node)
            await linkToRelevantNodes(node: node, chunk: chunk)
            enriched.append(chunk)
        }

        return enriched
    }

    private func createContextNode(from chunk: RankedChunk) -> ContextNode {
        ContextNode(
            type: .codeChunk(filePath: chunk.chunk.filePath),
            content: chunk.chunk.content,
            metadata: [
                "startLine": String(chunk.chunk.startLine),
                "endLine": String(chunk.chunk.endLine),
                "language": chunk.chunk.language.rawValue
            ]
        )
    }

    private func linkToRelevantNodes(node: ContextNode, chunk: RankedChunk) async {
        let contextPath = await contextTracker.getContextPath()

        for prevNode in contextPath.suffix(5) {
            let relationship = analyzeCodeRelationship(
                from: prevNode.content,
                to: chunk.chunk.content
            )

            if let rel = relationship {
                await contextTracker.link(
                    from: prevNode.id,
                    to: node.id,
                    relationship: rel,
                    strength: chunk.finalScore
                )
            }
        }
    }

    private func analyzeCodeRelationship(
        from source: String,
        to target: String
    ) -> ContextRelationship? {
        let sourceLower = source.lowercased()
        let targetLower = target.lowercased()

        if targetLower.contains("implement") && sourceLower.contains("interface") {
            return .implements
        }
        if sourceLower.contains("import") || sourceLower.contains("use") {
            return .dependsOn
        }
        if targetLower.contains("refactor") || targetLower.contains("improve") {
            return .refines
        }

        let sourceSymbols = extractSymbols(from: source)
        let targetSymbols = extractSymbols(from: target)
        let commonSymbols = sourceSymbols.intersection(targetSymbols)

        if !commonSymbols.isEmpty {
            return .references
        }

        return nil
    }

    private func extractSymbols(from code: String) -> Set<String> {
        let pattern = #"\b[A-Z][a-zA-Z0-9_]*\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let matches = regex.matches(
            in: code,
            range: NSRange(code.startIndex..., in: code)
        )

        return Set(matches.compactMap { match in
            guard let range = Range(match.range, in: code) else { return nil }
            return String(code[range])
        })
    }
}
