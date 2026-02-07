import AIPRDSharedUtilities
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Perplexity Sonar web search provider
/// Uses conversational search API for natural-language research queries
@available(iOS 15.0, macOS 12.0, *)
public final class PerplexitySearchProvider: WebResearchPort, Sendable {
    private let apiKey: String
    private let model: String
    private let baseURL: URL

    public init(
        apiKey: String,
        model: String = "sonar",
        baseURL: URL = URL(string: "https://api.perplexity.ai")!
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
    }

    public var providerName: String { "Perplexity" }

    public func search(query: String, maxResults: Int) async throws -> WebSearchResult {
        let request = try buildRequest(prompt: query)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebResearchError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw WebResearchError.apiError("Perplexity API returned \(httpResponse.statusCode)")
        }

        return try parseResponse(data, query: query, maxResults: maxResults)
    }

    public func researchTopic(topic: String, context: String) async throws -> WebSearchResult {
        let prompt = """
        Research the following topic in the context of software product development:
        Topic: \(topic)
        Context: \(context)

        Provide relevant findings, best practices, and competitive insights.
        """
        return try await search(query: prompt, maxResults: 5)
    }

    // MARK: - Private

    private func buildRequest(prompt: String) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "return_citations": true
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseResponse(_ data: Data, query: String, maxResults: Int) throws -> WebSearchResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WebResearchError.parseError("Invalid JSON response")
        }

        var snippets: [WebSnippet] = []
        var sources: [WebSource] = []

        // Extract content from choices
        if let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            snippets.append(WebSnippet(
                text: content,
                sourceURL: "",
                relevanceScore: 1.0
            ))
        }

        // Extract citations
        if let citations = json["citations"] as? [String] {
            for (index, citation) in citations.prefix(maxResults).enumerated() {
                sources.append(WebSource(
                    title: "Source \(index + 1)",
                    url: citation,
                    publishedDate: nil
                ))
            }
        }

        return WebSearchResult(query: query, snippets: snippets, sources: sources)
    }
}
