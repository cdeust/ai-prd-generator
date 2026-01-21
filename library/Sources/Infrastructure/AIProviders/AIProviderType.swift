import Foundation

/// AI Provider Type Enumeration
/// Defines supported provider types for production use
public enum AIProviderType: Sendable {
    case openAI
    case anthropic
    case gemini
    case appleFoundationModels
    case openRouter  // OpenRouter unified API (100+ models)
    case bedrock     // AWS Bedrock (Claude, Titan, Llama)
}
