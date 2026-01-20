import Foundation
import Domain
@preconcurrency import AWSBedrockRuntime
import AWSClientRuntime

/// AWS Bedrock AI Provider Implementation
/// Implements AIProviderPort using AWS Bedrock Runtime API
/// Following Single Responsibility: Only handles Bedrock API communication
/// Following naming convention: {Technology}Provider
///
/// AWS Bedrock provides access to multiple foundation models
/// - Anthropic Claude: anthropic.claude-sonnet-4-5-20250929
/// - Amazon Titan: amazon.titan-text-express-v1
/// - Meta Llama: meta.llama2-13b-chat-v1
@available(iOS 15.0, macOS 12.0, *)
public final class BedrockProvider: AIProviderPort, Sendable {
    // MARK: - Properties

    private let client: BedrockRuntimeClient
    private let modelId: String
    private let region: String
    private let payloadBuilder: BedrockPayloadBuilder
    private let responseParser: BedrockResponseParser

    // MARK: - Initialization

    public init(
        region: String = "us-east-1",
        accessKeyId: String,
        secretAccessKey: String,
        modelId: String = "anthropic.claude-sonnet-4-5-20250929"
    ) async throws {
        // Create AWS credentials
        let credentials = StaticCredential(
            accessKey: accessKeyId,
            secret: secretAccessKey
        )

        // Initialize Bedrock client
        let config = try await BedrockRuntimeClient.BedrockRuntimeClientConfiguration(
            awsCredentialIdentityResolver: credentials,
            region: region
        )

        self.client = BedrockRuntimeClient(config: config)
        self.modelId = modelId
        self.region = region
        self.payloadBuilder = BedrockPayloadBuilder()
        self.responseParser = BedrockResponseParser()
    }

    // MARK: - AIProviderPort Implementation

    public func generateText(
        prompt: String,
        temperature: Double
    ) async throws -> String {
        // Build request payload based on model
        let requestBody = try await payloadBuilder.buildPayload(
            for: modelId,
            prompt: prompt,
            temperature: temperature,
            stream: false
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
        temperature: Double
    ) async throws -> AsyncStream<String> {
        let requestBody = try await payloadBuilder.buildPayload(
            for: modelId,
            prompt: prompt,
            temperature: temperature,
            stream: true
        )

        let input = InvokeModelWithResponseStreamInput(
            body: requestBody,
            modelId: modelId
        )

        let response = try await client.invokeModelWithResponseStream(
            input: input
        )

        return AsyncStream { continuation in
            Task {
                do {
                    // AWS SDK response has a 'body' property that's the AsyncSequence
                    if let body = response.body {
                        for try await event in body {
                            // Pattern match on event type (it's an enum)
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
                                break  // Ignore other event types
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
        // Parse context window from model ID
        if modelId.contains("claude-sonnet-4-5") ||
           modelId.contains("claude-3-5-sonnet") ||
           modelId.contains("claude-3-opus") {
            return 200_000  // Claude: 200K tokens
        } else if modelId.contains("titan") {
            return 32_000   // Titan: 32K tokens
        } else if modelId.contains("llama") {
            return 8_000    // Llama: 8K tokens
        }

        // Conservative default for unknown models
        return 32_000
    }
}

/// AWS Static Credential Provider
/// Simple implementation for access key/secret authentication
private struct StaticCredential: AWSCredentialIdentityResolver {
    let accessKey: String
    let secret: String

    func getIdentity(identityProperties: Any?) async throws -> AWSCredentialIdentity {
        return AWSCredentialIdentity(
            accessKey: accessKey,
            secret: secret
        )
    }
}
