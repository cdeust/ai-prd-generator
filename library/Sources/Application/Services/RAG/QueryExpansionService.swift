import Foundation
import Domain

/// Expands queries for improved retrieval using HyDE and other techniques
/// Following Single Responsibility: Only handles query expansion
public struct QueryExpansionService: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Expand query using HyDE (Hypothetical Document Embeddings)
    /// Generates hypothetical answer, uses it for better retrieval
    public func expandWithHyDE(
        query: String,
        context: String? = nil
    ) async throws -> ExpandedQuery {
        let hypotheticalDoc = try await generateHypotheticalDocument(
            query: query,
            context: context
        )

        let decomposed = decomposeQuery(query)

        return ExpandedQuery(
            original: query,
            hypotheticalDocument: hypotheticalDoc,
            decomposedQueries: decomposed,
            allQueries: [query, hypotheticalDoc] + decomposed
        )
    }

    /// Generate multiple query variations for better recall
    public func generateVariations(
        _ query: String,
        count: Int = 3
    ) async throws -> [String] {
        let prompt = """
        Generate \(count) alternative phrasings of this query that preserve the same intent:

        Original: \(query)

        Output each variation on a new line, numbered 1-\(count).
        """

        let response = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.7
        )

        return parseVariations(from: response, originalQuery: query)
    }

    // MARK: - Private Methods

    /// HyDE: Generate hypothetical document that would answer the query
    private func generateHypotheticalDocument(
        query: String,
        context: String?
    ) async throws -> String {
        var prompt = """
        Generate a hypothetical code snippet or explanation that would perfectly answer this query:

        Query: \(query)
        """

        if let context = context, !context.isEmpty {
            prompt += """


            Context:
            \(context)
            """
        }

        prompt += """


        Generate a realistic code example or detailed explanation (2-3 paragraphs).
        Focus on what the answer would look like, not how to find it.
        """

        let response = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.7
        )

        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Decompose complex query into simpler sub-queries
    private func decomposeQuery(_ query: String) -> [String] {
        var decomposed: [String] = []

        // Extract key technical terms (simplified heuristic)
        let words = query
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }

        let technicalTerms = words.filter { word in
            // Heuristic: capitalized, contains numbers, or common code patterns
            word.first?.isUppercase == true ||
            word.contains(where: \.isNumber) ||
            word.contains("_") ||
            word.contains(where: { "[](){}".contains($0) })
        }

        // Create sub-queries from technical terms
        for term in technicalTerms.prefix(3) {
            let subQuery = "code related to \(term)"
            decomposed.append(subQuery)
        }

        // Extract action verbs
        let actionVerbs = ["implement", "create", "build", "generate", "handle", "process", "manage"]
        for verb in actionVerbs {
            if query.lowercased().contains(verb) {
                let verbQuery = query
                    .replacingOccurrences(of: "how to ", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "how do i ", with: "", options: .caseInsensitive)
                if verbQuery != query {
                    decomposed.append(verbQuery)
                }
            }
        }

        return Array(decomposed.prefix(3))
    }

    private func parseVariations(from response: String, originalQuery: String) -> [String] {
        let lines = response
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var variations: [String] = []

        for line in lines {
            // Remove numbering (1., 2., 3., etc.)
            let cleaned = line
                .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"^[-*]\s*"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !cleaned.isEmpty && cleaned != originalQuery {
                variations.append(cleaned)
            }
        }

        return variations
    }
}

