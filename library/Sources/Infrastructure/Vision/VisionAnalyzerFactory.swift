import Foundation
import Domain

/// Factory for creating vision analyzers based on provider type
@available(iOS 15.0, macOS 12.0, *)
public struct VisionAnalyzerFactory: Sendable {
    public enum Provider: String, Sendable {
        case apple = "Apple Intelligence"
        case anthropic = "Anthropic"
        case openai = "OpenAI"
        case gemini = "Google Gemini"
    }

    public init() {}

    public func createAnalyzer(
        for provider: Provider,
        apiKey: String? = nil
    ) -> VisionAnalysisPort {
        switch provider {
        case .apple:
            return AppleVisionAnalyzer(
                confidenceThreshold: 0.7,
                useAdvancedDetection: true
            )

        case .anthropic:
            guard let apiKey = apiKey else {
                fatalError("API key required for Anthropic Vision")
            }
            return AnthropicVisionAnalyzer(apiKey: apiKey)

        case .openai:
            guard let apiKey = apiKey else {
                fatalError("API key required for OpenAI Vision")
            }
            return OpenAIVisionAnalyzer(apiKey: apiKey)

        case .gemini:
            guard let apiKey = apiKey else {
                fatalError("API key required for Gemini Vision")
            }
            return GeminiVisionAnalyzer(apiKey: apiKey)
        }
    }

    public func createBestAnalyzer(apiKeys: [Provider: String]) -> VisionAnalysisPort {
        if apiKeys.isEmpty {
            return createAnalyzer(for: .apple)
        }

        return createAnalyzer(for: .apple)
    }
}
