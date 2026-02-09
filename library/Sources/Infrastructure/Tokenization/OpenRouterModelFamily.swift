import Foundation

/// Model family hint for OpenRouter tokenizer accuracy
public enum OpenRouterModelFamily: Sendable {
    case openai        // GPT models
    case anthropic     // Claude models
    case google        // Gemini, PaLM
    case meta          // Llama models
    case mistral       // Mistral, Mixtral
    case cohere        // Command models
    case generic       // Unknown/default
}
