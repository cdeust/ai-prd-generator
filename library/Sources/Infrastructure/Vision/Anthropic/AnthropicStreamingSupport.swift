import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Domain

/// Streaming support for Anthropic Vision analyzer
@available(iOS 15.0, macOS 12.0, *)
extension AnthropicVisionAnalyzer {
    /// Analyze mockup with streaming progress updates
    public func analyzeMockupStreaming(
        imageData: Data,
        prompt: String?
    ) -> AsyncThrowingStream<StreamingProgress, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await rateLimiter.waitForCapacity()

                    continuation.yield(.started)

                    let visionPrompt = buildAnalysisPrompt(
                        customPrompt: prompt
                    )
                    let request = try createStreamingRequest(
                        imageData: imageData,
                        prompt: visionPrompt
                    )

                    let output = try await streamVisionAPI(
                        request: request,
                        continuation: continuation
                    )

                    continuation.yield(.complete(output))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    internal func createStreamingRequest(
        imageData: Data,
        prompt: String
    ) throws -> URLRequest {
        var request = try createVisionRequest(
            imageData: imageData,
            prompt: prompt
        )

        let streamingBody = AnthropicVisionRequest(
            model: model,
            messages: [
                AnthropicVisionMessage(
                    role: "user",
                    content: [
                        .image(
                            AnthropicVisionImageBlock(
                                imageData: imageData,
                                mimeType: "image/png"
                            )
                        ),
                        .text(prompt)
                    ]
                )
            ],
            maxTokens: 4096,
            temperature: 0.0,
            stream: true
        )

        request.httpBody = try JSONEncoder().encode(streamingBody)
        return request
    }

    internal func streamVisionAPI(
        request: URLRequest,
        continuation: AsyncThrowingStream<StreamingProgress, Error>
            .Continuation
    ) async throws -> VisionAnalysisOutput {
        let (bytes, response) = try await URLSession.shared.bytes(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MockupAnalysisError.providerError("Stream failed")
        }

        let parser = AnthropicStreamingParser()
        var buffer = ""

        for try await line in bytes.lines {
            guard let chunk = try parser.parseChunk(line) else {
                continue
            }

            switch chunk {
            case .content(let streamChunk):
                if let text = streamChunk.delta?.text {
                    buffer += text

                    if let partial = parser.extractPartialResults(
                        from: buffer
                    ) {
                        continuation.yield(
                            .componentsDetected(partial.components.count)
                        )
                        continuation.yield(
                            .flowsDetected(partial.flows.count)
                        )
                    }
                }

            case .done:
                break
            }
        }

        continuation.yield(.validating)
        return try parser.parseFinalBuffer(buffer)
    }
}

