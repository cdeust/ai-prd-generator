import Foundation

/// AI model type with capabilities.
///
/// Different models have different context windows and capabilities:
/// - Apple Intelligence: 4K context, on-device, free
/// - Claude: 200K context, cloud, prompt caching
/// - GPT-4: 128K context, cloud, balanced
public enum ModelType: Sendable, Codable {
    case appleIntelligence(contextLimit: Int = 4_096)
    case claude(contextLimit: Int = 200_000)
    case gpt4(contextLimit: Int = 128_000)
    case custom(contextLimit: Int)

    /// Maximum context window in tokens
    public var contextLimit: Int {
        switch self {
        case .appleIntelligence(let limit): return limit
        case .claude(let limit): return limit
        case .gpt4(let limit): return limit
        case .custom(let limit): return limit
        }
    }

    /// Requires aggressive compression (< 10K context)
    public var requiresAggressiveCompression: Bool {
        contextLimit < 10_000
    }

    /// Supports guided generation
    public var supportsGuidedGeneration: Bool {
        true
    }

    /// Supports caching (KV cache or prompt caching)
    public var supportsCaching: Bool {
        switch self {
        case .appleIntelligence: return true
        case .claude: return true
        case .gpt4: return false
        case .custom: return false
        }
    }

    /// On-device execution
    public var isOnDevice: Bool {
        switch self {
        case .appleIntelligence: return true
        default: return false
        }
    }

    /// Cost per 1M input tokens (USD)
    public var costPerMillionInputTokens: Double {
        switch self {
        case .appleIntelligence: return 0.0
        case .claude: return 3.0
        case .gpt4: return 10.0
        case .custom: return 0.0
        }
    }

    /// Cost per 1M output tokens (USD)
    public var costPerMillionOutputTokens: Double {
        switch self {
        case .appleIntelligence: return 0.0
        case .claude: return 15.0
        case .gpt4: return 30.0
        case .custom: return 0.0
        }
    }
}
