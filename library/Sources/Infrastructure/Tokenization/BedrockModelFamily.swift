import Foundation

/// Model family for Bedrock tokenizer selection
public enum BedrockModelFamily: Sendable {
    case claude       // Anthropic Claude models
    case titan        // Amazon Titan models
    case llama        // Meta Llama models
    case mistral      // Mistral AI models
    case cohere       // Cohere Command models
}
