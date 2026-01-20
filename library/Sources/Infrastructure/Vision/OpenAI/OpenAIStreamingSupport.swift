import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Domain

/// Streaming support for OpenAI Vision analyzer
@available(iOS 15.0, macOS 12.0, *)
extension OpenAIVisionAnalyzer {
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

                    let visionPrompt = buildPrompt(customPrompt: prompt)
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
        let url = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64Image = imageData.base64EncodedString()
        let body: [String: Any] = [
            "model": model,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt],
                    ["type": "image_url", "image_url": ["url": "data:image/png;base64,\(base64Image)"]]
                ]
            ]],
            "max_tokens": 4096,
            "stream": true
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
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
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw errorMapper.mapHTTPError(
                statusCode: statusCode,
                data: Data()
            )
        }

        let parser = OpenAIStreamingParser()
        var buffer = ""

        for try await line in bytes.lines {
            guard let chunk = try parser.parseChunk(line) else {
                continue
            }

            switch chunk {
            case .content(let streamChunk):
                if let choices = streamChunk.choices,
                   let delta = choices.first?.delta,
                   let text = delta.content {
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

