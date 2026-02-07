import Foundation

/// AI provider API keys parsed from environment
struct ConfigurationAIProviderKeys {
    let openAI: String?
    let anthropic: String?
    let gemini: String?
    let openRouter: String?
    let bedrockAccessKeyId: String?
    let bedrockSecretAccessKey: String?
    let bedrockRegion: String?
    let primary: String?
}
