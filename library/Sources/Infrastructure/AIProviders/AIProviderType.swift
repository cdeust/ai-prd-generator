import Foundation

/// AI Provider Type Enumeration
/// Defines supported provider types
public enum AIProviderType: Sendable {
    case openAI
    case anthropic
    case gemini
    case appleFoundationModels
    case openRouter  // NEW: OpenRouter unified API (100+ models)
    case bedrock     // NEW: AWS Bedrock (Claude, Titan, Llama)
    case mock        // NEW: Mock provider for testing without API credentials
}
