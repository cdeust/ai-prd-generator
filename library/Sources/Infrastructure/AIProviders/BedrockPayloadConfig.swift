import Foundation

/// Configuration for Bedrock payload building
/// Configurable token limits and reasoning budgets
public struct BedrockPayloadConfig: Sendable {
    public let maxOutputTokens: Int
    public let reasoningTokensLow: Int
    public let reasoningTokensMedium: Int
    public let reasoningTokensHigh: Int
    public let topP: Double

    public init(
        maxOutputTokens: Int = 4096,
        reasoningTokensLow: Int = 10_000,
        reasoningTokensMedium: Int = 25_000,
        reasoningTokensHigh: Int = 50_000,
        topP: Double = 0.9
    ) {
        self.maxOutputTokens = maxOutputTokens
        self.reasoningTokensLow = reasoningTokensLow
        self.reasoningTokensMedium = reasoningTokensMedium
        self.reasoningTokensHigh = reasoningTokensHigh
        self.topP = topP
    }

    public static let `default` = BedrockPayloadConfig()
}
