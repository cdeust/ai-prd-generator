import AIPRDSharedUtilities
import Foundation

/// No-op fallback when no web research API keys are configured
public final class DegradedWebResearchProvider: WebResearchPort, Sendable {
    public init() {}

    public var providerName: String { "Degraded (no API key)" }

    public func search(query: String, maxResults: Int) async throws -> WebSearchResult {
        WebSearchResult(query: query, snippets: [], sources: [])
    }

    public func researchTopic(topic: String, context: String) async throws -> WebSearchResult {
        WebSearchResult(query: topic, snippets: [], sources: [])
    }
}
