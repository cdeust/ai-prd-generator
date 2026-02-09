import Foundation
import AIPRDSharedUtilities

/// Bedrock Payload Builder
/// Constructs model-specific request payloads for AWS Bedrock
/// Following Single Responsibility: Only builds request payloads
/// Following naming convention: {Purpose}Builder
///
/// Different Bedrock models require different JSON schemas
actor BedrockPayloadBuilder {

    private let config: BedrockPayloadConfig

    init(config: BedrockPayloadConfig = .default) {
        self.config = config
    }

    func buildPayload(
        for modelId: String,
        prompt: String,
        temperature: Double,
        stream: Bool,
        reasoningEffort: ReasoningEffort
    ) throws -> Data {
        if modelId.hasPrefix("anthropic.") {
            return try buildAnthropicPayload(
                prompt: prompt,
                temperature: temperature,
                stream: stream,
                reasoningEffort: reasoningEffort
            )
        } else if modelId.hasPrefix("amazon.nova") {
            return try buildNovaPayload(
                prompt: prompt,
                temperature: temperature,
                reasoningEffort: reasoningEffort
            )
        } else if modelId.hasPrefix("amazon.titan") {
            return try buildTitanPayload(
                prompt: prompt,
                temperature: temperature
            )
        } else if modelId.hasPrefix("meta.llama") {
            return try buildLlamaPayload(
                prompt: prompt,
                temperature: temperature
            )
        } else {
            throw AIProviderError.invalidConfiguration(
                "Unsupported Bedrock model: \(modelId)"
            )
        }
    }

    // MARK: - Anthropic Payload

    private func buildAnthropicPayload(
        prompt: String,
        temperature: Double,
        stream: Bool,
        reasoningEffort: ReasoningEffort
    ) throws -> Data {
        var payload: [String: Any] = [
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": config.maxOutputTokens,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": temperature
        ]

        // Map ReasoningEffort to thinking budget
        let budgetTokens = thinkingBudget(for: reasoningEffort)
        if budgetTokens > 0 {
            payload["thinking"] = [
                "type": "enabled",
                "budget_tokens": budgetTokens
            ]
        }

        return try JSONSerialization.data(withJSONObject: payload)
    }

    /// Maps ReasoningEffort to thinking budget tokens
    /// - Parameter effort: The reasoning effort level
    /// - Returns: Token budget (0 means disabled)
    private func thinkingBudget(for effort: ReasoningEffort) -> Int {
        switch effort {
        case .none:
            return 0
        case .low:
            return config.reasoningTokensLow
        case .medium:
            return config.reasoningTokensMedium
        case .high:
            return config.reasoningTokensHigh
        }
    }

    // MARK: - Nova Payload

    private func buildNovaPayload(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) throws -> Data {
        var payload: [String: Any] = [
            "inputText": prompt,
            "textGenerationConfig": [
                "maxTokenCount": config.maxOutputTokens,
                "temperature": temperature
            ]
        ]

        // Map ReasoningEffort to Nova's reasoningConfig
        if reasoningEffort != .none {
            payload["reasoningConfig"] = [
                "type": "enabled",
                "maxReasoningEffort": reasoningEffort.rawValue
            ]
        }

        return try JSONSerialization.data(withJSONObject: payload)
    }

    // MARK: - Titan Payload

    private func buildTitanPayload(
        prompt: String,
        temperature: Double
    ) throws -> Data {
        let payload: [String: Any] = [
            "inputText": prompt,
            "textGenerationConfig": [
                "maxTokenCount": config.maxOutputTokens,
                "temperature": temperature,
                "topP": config.topP
            ]
        ]

        return try JSONSerialization.data(withJSONObject: payload)
    }

    // MARK: - Llama Payload

    private func buildLlamaPayload(
        prompt: String,
        temperature: Double
    ) throws -> Data {
        let payload: [String: Any] = [
            "prompt": prompt,
            "max_gen_len": config.maxOutputTokens,
            "temperature": temperature,
            "top_p": config.topP
        ]

        return try JSONSerialization.data(withJSONObject: payload)
    }
}
