import AIPRDSharedUtilities
import Foundation

/// AI Provider Configuration
/// Encapsulates provider-specific settings
/// Following value type for immutability
///
/// Environment Variables:
/// - `ANTHROPIC_MODEL`: Default Anthropic model (default: claude-sonnet-4-5-20250514)
/// - `ANTHROPIC_API_VERSION`: Anthropic API version (default: 2023-06-01)
/// - `OPENAI_MODEL`: Default OpenAI model (default: gpt-4.1)
/// - `GEMINI_MODEL`: Default Gemini model (default: gemini-2.5-pro)
/// - `BEDROCK_MODEL`: Default Bedrock model (default: anthropic.claude-sonnet-4-5-20250514-v1:0)
/// - `OPENROUTER_MODEL`: Default OpenRouter model (default: anthropic/claude-sonnet-4-5)
public struct AIProviderConfiguration: Sendable {
    public let type: AIProviderType
    public let apiKey: String?
    public let model: String?
    public let baseURL: URL?
    public let apiVersion: String?

    // AWS Bedrock-specific fields
    public let region: String?
    public let accessKeyId: String?
    public let secretAccessKey: String?

    // LLM generation parameters (configurable via env vars)
    public let maxOutputTokens: Int
    public let reasoningTokensLow: Int
    public let reasoningTokensMedium: Int
    public let reasoningTokensHigh: Int

    public init(
        type: AIProviderType,
        apiKey: String? = nil,
        model: String? = nil,
        baseURL: URL? = nil,
        apiVersion: String? = nil,
        region: String? = nil,
        accessKeyId: String? = nil,
        secretAccessKey: String? = nil,
        maxOutputTokens: Int = 8192,
        reasoningTokensLow: Int = 10_000,
        reasoningTokensMedium: Int = 25_000,
        reasoningTokensHigh: Int = 50_000
    ) {
        self.type = type
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.apiVersion = apiVersion
        self.region = region
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.maxOutputTokens = maxOutputTokens
        self.reasoningTokensLow = reasoningTokensLow
        self.reasoningTokensMedium = reasoningTokensMedium
        self.reasoningTokensHigh = reasoningTokensHigh
    }

    /// Default model for each provider (configurable via env vars)
    /// Updated for Q1 2026 latest models (Claude 4.6 released Feb 2026)
    public static func defaultModel(for provider: AIProviderType) -> String {
        let env = ProcessInfo.processInfo.environment
        switch provider {
        case .anthropic:
            // Claude Sonnet 4.6 (Feb 2026) - balanced performance/cost
            // Use ANTHROPIC_MODEL=claude-opus-4-6-20260201 for most capable
            return env["ANTHROPIC_MODEL"] ?? "claude-sonnet-4-6-20260201"
        case .openAI:
            // GPT-5.2 (Dec 2025) - latest reasoning model
            return env["OPENAI_MODEL"] ?? "gpt-5.2"
        case .gemini:
            // Gemini 3.0 Pro (Jan 2026) - latest multimodal
            return env["GEMINI_MODEL"] ?? "gemini-3.0-pro"
        case .bedrock:
            // Claude Sonnet 4.6 on Bedrock
            return env["BEDROCK_MODEL"] ?? "anthropic.claude-sonnet-4-6-20260201-v1:0"
        case .openRouter:
            return env["OPENROUTER_MODEL"] ?? "anthropic/claude-sonnet-4-6"
        case .appleFoundationModels:
            return "apple-foundation-model-3b"
        case .qwen:
            // Qwen 3.0 (2026)
            return env["QWEN_MODEL"] ?? "qwen3-max"
        case .zhipu:
            // GLM-5 (2026)
            return env["ZHIPU_MODEL"] ?? "glm-5"
        case .moonshot:
            return env["MOONSHOT_MODEL"] ?? "moonshot-v2-256k"
        case .minimax:
            return env["MINIMAX_MODEL"] ?? "abab7-chat"
        case .deepseek:
            // DeepSeek-V3 (2026)
            return env["DEEPSEEK_MODEL"] ?? "deepseek-v3"
        }
    }

    /// Default API version for Anthropic (configurable via env var)
    /// API version 2025-01-01 includes extended thinking and prompt caching
    public static var anthropicAPIVersion: String {
        ProcessInfo.processInfo.environment["ANTHROPIC_API_VERSION"] ?? "2025-01-01"
    }

    /// Default base URL for each provider (configurable via env vars)
    public static func defaultBaseURL(for provider: AIProviderType) -> URL? {
        let env = ProcessInfo.processInfo.environment
        switch provider {
        case .anthropic:
            return URL(string: env["ANTHROPIC_BASE_URL"] ?? "https://api.anthropic.com/v1")
        case .openAI:
            return URL(string: env["OPENAI_BASE_URL"] ?? "https://api.openai.com/v1")
        case .gemini:
            return URL(string: env["GEMINI_BASE_URL"] ?? "https://generativelanguage.googleapis.com/v1beta")
        case .openRouter:
            return URL(string: env["OPENROUTER_BASE_URL"] ?? "https://openrouter.ai/api/v1")
        default:
            return nil
        }
    }
}
