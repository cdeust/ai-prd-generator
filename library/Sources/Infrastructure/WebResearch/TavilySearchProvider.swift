import AIPRDSharedUtilities
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Tavily web search provider
/// Uses structured extraction API for focused web research
@available(iOS 15.0, macOS 12.0, *)
public final class TavilySearchProvider: WebResearchPort, Sendable {
    private let apiKey: String
    private let baseURL: URL

    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.tavily.com")!
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    public var providerName: String { "Tavily" }

    public func search(query: String, maxResults: Int) async throws -> WebSearchResult {
        let request = try buildRequest(query: query, maxResults: maxResults)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebResearchError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw WebResearchError.apiError("Tavily API returned \(httpResponse.statusCode)")
        }

        return try parseResponse(data, query: query)
    }

    public func researchTopic(topic: String, context: String) async throws -> WebSearchResult {
        let query = "\(topic) \(context)"
        return try await search(query: query, maxResults: 5)
    }

    // MARK: - Private

    private func buildRequest(query: String, maxResults: Int) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("search")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "api_key": apiKey,
            "query": query,
            "max_results": maxResults,
            "include_answer": true,
            "search_depth": "advanced"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseResponse(_ data: Data, query: String) throws -> WebSearchResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WebResearchError.parseError("Invalid JSON response")
        }

        var snippets: [WebSnippet] = []
        var sources: [WebSource] = []

        // Extract answer summary
        if let answer = json["answer"] as? String {
            snippets.append(WebSnippet(
                text: answer,
                sourceURL: "",
                relevanceScore: 1.0
            ))
        }

        // Extract results
        if let results = json["results"] as? [[String: Any]] {
            for result in results {
                let title = result["title"] as? String ?? ""
                let url = result["url"] as? String ?? ""
                let content = result["content"] as? String ?? ""
                let score = result["score"] as? Double ?? 0.5
                let publishedDate = result["published_date"] as? String

                snippets.append(WebSnippet(
                    text: content,
                    sourceURL: url,
                    relevanceScore: score
                ))

                sources.append(WebSource(
                    title: title,
                    url: url,
                    publishedDate: publishedDate
                ))
            }
        }

        return WebSearchResult(query: query, snippets: snippets, sources: sources)
    }
}
