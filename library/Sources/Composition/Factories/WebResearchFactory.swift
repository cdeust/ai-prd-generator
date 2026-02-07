import AIPRDSharedUtilities
import Foundation
import InfrastructureCore

/// Factory for creating web research providers
/// Priority: Perplexity (if key) > Tavily (if key) > Degraded
@available(iOS 15.0, macOS 12.0, *)
struct WebResearchFactory {

    static func create(configuration: Configuration) -> WebResearchFactoryResult {
        guard configuration.webResearchEnabled else {
            return WebResearchFactoryResult(
                provider: DegradedWebResearchProvider(),
                isDegraded: true
            )
        }

        // Priority: Perplexity > Tavily > Degraded
        if let perplexityKey = configuration.perplexityAPIKey, !perplexityKey.isEmpty {
            return WebResearchFactoryResult(
                provider: PerplexitySearchProvider(apiKey: perplexityKey),
                isDegraded: false
            )
        }

        if let tavilyKey = configuration.tavilyAPIKey, !tavilyKey.isEmpty {
            return WebResearchFactoryResult(
                provider: TavilySearchProvider(apiKey: tavilyKey),
                isDegraded: false
            )
        }

        return WebResearchFactoryResult(
            provider: DegradedWebResearchProvider(),
            isDegraded: true
        )
    }
}
