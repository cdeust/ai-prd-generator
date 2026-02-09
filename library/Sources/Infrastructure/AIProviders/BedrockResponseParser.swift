import Foundation
import AIPRDSharedUtilities

/// Bedrock Response Parser
/// Parses model-specific responses from AWS Bedrock
/// Following Single Responsibility: Only parses responses
/// Following naming convention: {Purpose}Parser
///
/// Different Bedrock models return different JSON schemas
actor BedrockResponseParser {
    func parseResponse(
        _ data: Data,
        for modelId: String
    ) throws -> String {
        if modelId.hasPrefix("anthropic.") {
            return try parseAnthropicResponse(data)
        } else if modelId.hasPrefix("amazon.titan") {
            return try parseTitanResponse(data)
        } else if modelId.hasPrefix("meta.llama") {
            return try parseLlamaResponse(data)
        } else {
            throw AIProviderError.invalidConfiguration(
                "Unsupported Bedrock model: \(modelId)"
            )
        }
    }

    func parseStreamChunk(
        _ data: Data,
        for modelId: String
    ) throws -> String? {
        if modelId.hasPrefix("anthropic.") {
            return try parseAnthropicStreamChunk(data)
        } else if modelId.hasPrefix("amazon.titan") {
            return try parseTitanStreamChunk(data)
        } else if modelId.hasPrefix("meta.llama") {
            return try parseLlamaStreamChunk(data)
        } else {
            throw AIProviderError.invalidConfiguration(
                "Unsupported Bedrock model: \(modelId)"
            )
        }
    }

    // MARK: - Anthropic Response

    private func parseAnthropicResponse(_ data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(
            with: data
        ) as? [String: Any]

        guard let content = json?["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw AIProviderError.invalidResponse
        }

        return text
    }

    private func parseAnthropicStreamChunk(_ data: Data) throws -> String? {
        let json = try JSONSerialization.jsonObject(
            with: data
        ) as? [String: Any]

        guard let type = json?["type"] as? String else {
            return nil
        }

        if type == "content_block_delta" {
            guard let delta = json?["delta"] as? [String: Any],
                  let text = delta["text"] as? String else {
                return nil
            }
            return text
        }

        return nil
    }

    // MARK: - Titan Response

    private func parseTitanResponse(_ data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(
            with: data
        ) as? [String: Any]

        guard let results = json?["results"] as? [[String: Any]],
              let text = results.first?["outputText"] as? String else {
            throw AIProviderError.invalidResponse
        }

        return text
    }

    private func parseTitanStreamChunk(_ data: Data) throws -> String? {
        let json = try JSONSerialization.jsonObject(
            with: data
        ) as? [String: Any]

        guard let outputText = json?["outputText"] as? String else {
            return nil
        }

        return outputText
    }

    // MARK: - Llama Response

    private func parseLlamaResponse(_ data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(
            with: data
        ) as? [String: Any]

        guard let generation = json?["generation"] as? String else {
            throw AIProviderError.invalidResponse
        }

        return generation
    }

    private func parseLlamaStreamChunk(_ data: Data) throws -> String? {
        let json = try JSONSerialization.jsonObject(
            with: data
        ) as? [String: Any]

        guard let generation = json?["generation"] as? String else {
            return nil
        }

        return generation
    }
}
