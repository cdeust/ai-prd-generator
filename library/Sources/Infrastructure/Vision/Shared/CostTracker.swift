import Foundation

/// Tracks API usage costs for vision analysis providers
public actor CostTracker: Sendable {
    private var totalCost: Decimal
    private var requestCount: Int
    private var usageByProvider: [String: ProviderUsage]

    public struct ProviderUsage: Sendable {
        public var requests: Int
        public var totalCost: Decimal
        public var inputTokens: Int
        public var outputTokens: Int

        public init() {
            self.requests = 0
            self.totalCost = 0
            self.inputTokens = 0
            self.outputTokens = 0
        }
    }

    public struct Pricing {
        public static let anthropicVisionCostPer1KTokens: Decimal = 0.003
        public static let openAIGPT4VCostPer1KTokens: Decimal = 0.01
        public static let geminiVisionCostPer1KTokens: Decimal = 0.002
    }

    public init() {
        self.totalCost = 0
        self.requestCount = 0
        self.usageByProvider = [:]
    }

    public func recordUsage(
        provider: String,
        inputTokens: Int,
        outputTokens: Int
    ) {
        let cost = calculateCost(
            provider: provider,
            inputTokens: inputTokens,
            outputTokens: outputTokens
        )

        totalCost += cost
        requestCount += 1

        var usage = usageByProvider[provider] ?? ProviderUsage()
        usage.requests += 1
        usage.totalCost += cost
        usage.inputTokens += inputTokens
        usage.outputTokens += outputTokens
        usageByProvider[provider] = usage
    }

    public func getCurrentCost() -> Decimal {
        totalCost
    }

    public func getRequestCount() -> Int {
        requestCount
    }

    public func getUsage(for provider: String) -> ProviderUsage? {
        usageByProvider[provider]
    }

    public func reset() {
        totalCost = 0
        requestCount = 0
        usageByProvider.removeAll()
    }

    private func calculateCost(
        provider: String,
        inputTokens: Int,
        outputTokens: Int
    ) -> Decimal {
        let totalTokens = Decimal(inputTokens + outputTokens)
        let costPer1K: Decimal

        switch provider.lowercased() {
        case "anthropic":
            costPer1K = Pricing.anthropicVisionCostPer1KTokens
        case "openai":
            costPer1K = Pricing.openAIGPT4VCostPer1KTokens
        case "gemini":
            costPer1K = Pricing.geminiVisionCostPer1KTokens
        case "apple":
            return 0
        default:
            return 0
        }

        return (totalTokens / 1000) * costPer1K
    }
}

