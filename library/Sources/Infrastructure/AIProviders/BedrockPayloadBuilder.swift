import Foundation
import Domain

/// Bedrock Payload Builder
/// Constructs model-specific request payloads for AWS Bedrock
/// Following Single Responsibility: Only builds request payloads
/// Following naming convention: {Purpose}Builder
///
/// Different Bedrock models require different JSON schemas
actor BedrockPayloadBuilder {
    func buildPayload(
        for modelId: String,
        prompt: String,
        temperature: Double,
        stream: Bool,
        extendedThinking: Bool
    ) throws -> Data {
        if modelId.hasPrefix("anthropic.") {
            return try buildAnthropicPayload(
                prompt: prompt,
                temperature: temperature,
                stream: stream,
                extendedThinking: extendedThinking
            )
        } else if modelId.hasPrefix("amazon.nova") {
            return try buildNovaPayload(
                prompt: prompt,
                temperature: temperature,
                extendedThinking: extendedThinking
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
        extendedThinking: Bool
    ) throws -> Data {
        var payload: [String: Any] = [
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 4096,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": temperature
        ]

        // Add extended thinking for Claude models (50K token budget)
        if extendedThinking {
            payload["thinking"] = [
                "type": "enabled",
                "budget_tokens": 50000
            ]
        }

        return try JSONSerialization.data(withJSONObject: payload)
    }

    // MARK: - Nova Payload

    private func buildNovaPayload(
        prompt: String,
        temperature: Double,
        extendedThinking: Bool
    ) throws -> Data {
        var payload: [String: Any] = [
            "inputText": prompt,
            "textGenerationConfig": [
                "maxTokenCount": 4096,
                "temperature": temperature
            ]
        ]

        // Add extended thinking for Nova models
        if extendedThinking {
            payload["reasoningConfig"] = [
                "type": "enabled",
                "maxReasoningEffort": "high"
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
                "maxTokenCount": 4096,
                "temperature": temperature,
                "topP": 0.9
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
            "max_gen_len": 4096,
            "temperature": temperature,
            "top_p": 0.9
        ]

        return try JSONSerialization.data(withJSONObject: payload)
    }
}
