import Foundation

/// Static configuration for Chinese AI providers
/// All use OpenAI-compatible API format, enabling ~80% code reuse via OpenAIProvider
public struct ChineseProviderConfig: Sendable {
    public let name: String
    public let baseURL: URL
    public let defaultModel: String
    public let contextWindow: Int
    public let reasoningModel: String?
    public let visionModel: String?

    /// Qwen (Alibaba / Tongyi Qianwen)
    /// International endpoint: Qwen3-Max (262K), Qwen-Plus (1M), QwQ-Plus reasoning
    /// Vision: qwen3-vl-plus (262K multimodal)
    public static let qwen = ChineseProviderConfig(
        name: "Qwen",
        baseURL: URL(string: "https://dashscope-intl.aliyuncs.com/compatible-mode/v1")!,
        defaultModel: "qwen3-max",
        contextWindow: 262_144,
        reasoningModel: "qwq-plus",
        visionModel: "qwen3-vl-plus"
    )

    /// Zhipu AI (GLM series)
    /// GLM-4.7 with 200K context, GLM-4.6V for vision (128K multimodal)
    /// Thinking mode available via parameter toggle on GLM-4.7
    public static let zhipu = ChineseProviderConfig(
        name: "Zhipu AI",
        baseURL: URL(string: "https://api.z.ai/api/paas/v4/")!,
        defaultModel: "glm-4.7",
        contextWindow: 200_000,
        reasoningModel: nil,
        visionModel: "glm-4.6v"
    )

    /// Moonshot (Kimi)
    /// K2.5 with 262K context, native multimodal + thinking mode
    /// Thinking enabled via temperature=1.0 + top_p=0.95, instant via thinking=false
    public static let moonshot = ChineseProviderConfig(
        name: "Moonshot Kimi",
        baseURL: URL(string: "https://api.moonshot.ai/v1")!,
        defaultModel: "kimi-k2.5",
        contextWindow: 262_144,
        reasoningModel: "kimi-k2.5",
        visionModel: "kimi-k2.5"
    )

    /// MiniMax
    /// M2.1 (256K text), M1 (1M reasoning), MiniMax-VL-01 for vision
    public static let minimax = ChineseProviderConfig(
        name: "MiniMax",
        baseURL: URL(string: "https://api.minimax.chat/v1")!,
        defaultModel: "MiniMax-M2.1",
        contextWindow: 256_000,
        reasoningModel: "MiniMax-M1",
        visionModel: "MiniMax-VL-01"
    )

    /// Look up config by AIProviderType
    public static func config(for type: AIProviderType) -> ChineseProviderConfig? {
        switch type {
        case .qwen: return .qwen
        case .zhipu: return .zhipu
        case .moonshot: return .moonshot
        case .minimax: return .minimax
        default: return nil
        }
    }
}
