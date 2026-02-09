import Foundation
import AIPRDSharedUtilities
@preconcurrency import AWSBedrockRuntime
import AWSClientRuntime

/// AWS Bedrock AI Provider Implementation
/// Implements AIProviderPort using AWS Bedrock Runtime API
/// Following Single Responsibility: Only handles Bedrock API communication
@available(iOS 15.0, macOS 12.0, *)
public final class BedrockProvider: AIProviderPort, Sendable {
    private let client: BedrockRuntimeClient
    private let modelId: String
    private let region: String
    private let payloadBuilder: BedrockPayloadBuilder
    private let responseParser: BedrockResponseParser

    public init(
        region: String = "us-east-1",
        accessKeyId: String,
        secretAccessKey: String,
        modelId: String = "anthropic.claude-sonnet-4-5-20250929",
        maxOutputTokens: Int = 4096,
        reasoningTokensLow: Int = 10_000,
        reasoningTokensMedium: Int = 25_000,
        reasoningTokensHigh: Int = 50_000
    ) async throws {
        let credential = BedrockStaticCredential(
            accessKey: accessKeyId,
            secret: secretAccessKey
        )
        let resolver = BedrockCredentialResolver(credential: credential)

        let awsConfig = try await BedrockRuntimeClient.BedrockRuntimeClientConfiguration(
            awsCredentialIdentityResolver: resolver,
            region: region
        )

        self.client = BedrockRuntimeClient(config: awsConfig)
        self.modelId = modelId
        self.region = region
        self.payloadBuilder = BedrockPayloadBuilder(
            config: BedrockPayloadConfig(
                maxOutputTokens: maxOutputTokens,
                reasoningTokensLow: reasoningTokensLow,
                reasoningTokensMedium: reasoningTokensMedium,
                reasoningTokensHigh: reasoningTokensHigh,
                topP: 0.9
            )
        )
        self.responseParser = BedrockResponseParser()
    }

    public func generateText(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> String {
        let requestBody = try await payloadBuilder.buildPayload(
            for: modelId,
            prompt: prompt,
            temperature: temperature,
            stream: false,
            reasoningEffort: reasoningEffort
        )

        let input = InvokeModelInput(
            body: requestBody,
            modelId: modelId
        )

        let response = try await client.invokeModel(input: input)

        guard let responseBody = response.body else {
            throw AIProviderError.invalidResponse
        }

        return try await responseParser.parseResponse(
            responseBody,
            for: modelId
        )
    }

    public func streamText(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> AsyncStream<String> {
        let requestBody = try await payloadBuilder.buildPayload(
            for: modelId,
            prompt: prompt,
            temperature: temperature,
            stream: true,
            reasoningEffort: reasoningEffort
        )

        let input = InvokeModelWithResponseStreamInput(
            body: requestBody,
            modelId: modelId
        )

        let response = try await client.invokeModelWithResponseStream(input: input)

        return AsyncStream { continuation in
            Task {
                do {
                    if let body = response.body {
                        for try await event in body {
                            switch event {
                            case .chunk(let chunkData):
                                if let bytes = chunkData.bytes,
                                   let text = try await self.responseParser.parseStreamChunk(
                                    bytes,
                                    for: self.modelId
                                   ) {
                                    continuation.yield(text)
                                }
                            default:
                                break
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }

    public var providerName: String { "AWS Bedrock" }
    public var modelName: String { modelId }

    public var contextWindowSize: Int {
        if modelId.contains("claude-sonnet-4-5") ||
           modelId.contains("claude-3-5-sonnet") ||
           modelId.contains("claude-3-opus") {
            return 200_000
        } else if modelId.contains("titan") {
            return 32_000
        } else if modelId.contains("llama") {
            return 8_000
        }
        return 32_000
    }
}
