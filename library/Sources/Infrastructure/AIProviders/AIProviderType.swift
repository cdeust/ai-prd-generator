import AIPRDSharedUtilities
import Foundation

/// AI Provider Type Enumeration
/// Defines supported provider types for production use
public enum AIProviderType: String, Sendable, CaseIterable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case gemini = "gemini"
    case appleFoundationModels = "apple"
    case openRouter = "openrouter"  // OpenRouter unified API (100+ models)
    case bedrock = "bedrock"        // AWS Bedrock (Claude, Titan, Llama)
    case qwen = "qwen"              // Alibaba Qwen
    case zhipu = "zhipu"            // Zhipu GLM
    case moonshot = "moonshot"      // Moonshot AI
    case minimax = "minimax"        // MiniMax AI
    case deepseek = "deepseek"      // DeepSeek AI
}
