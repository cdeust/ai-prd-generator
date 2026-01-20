import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Domain

/// Streaming support for Gemini Vision analyzer
@available(iOS 15.0, macOS 12.0, *)
extension GeminiVisionAnalyzer {
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
        let url = baseURL.appendingPathComponent("models/\(model):streamGenerateContent")
            .appendingPathComponent("?key=\(apiKey)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64Image = imageData.base64EncodedString()
        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/png", "data": base64Image]]
                ]
            ]]
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

        let parser = GeminiStreamingParser()
        var buffer = ""

        for try await line in bytes.lines {
            guard let chunk = try parser.parseChunk(line) else {
                continue
            }

            switch chunk {
            case .content(let streamChunk):
                if let candidate = streamChunk.candidates?.first,
                   let content = candidate.content,
                   let parts = content.parts,
                   let text = parts.first?.text {
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

