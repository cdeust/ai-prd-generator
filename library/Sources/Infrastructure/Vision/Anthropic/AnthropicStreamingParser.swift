import Foundation

/// Parser for Anthropic streaming responses
struct AnthropicStreamingParser: Sendable {
    /// Parse streaming chunk from Anthropic API
    func parseChunk(_ line: String) throws -> AnthropicStreamResponse? {
        guard line.hasPrefix("data: ") else {
            return nil
        }

        let jsonString = String(line.dropFirst(6))

        guard jsonString != "[DONE]" else {
            return .done
        }

        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        let chunk = try JSONDecoder().decode(
            AnthropicResponseChunk.self,
            from: data
        )

        return .content(chunk)
    }

    /// Try to extract partial results from accumulated buffer
    func extractPartialResults(from buffer: String) -> PartialResults? {
        var components: [VisionAnalysisOutput.ComponentDTO] = []
        var flows: [VisionAnalysisOutput.UserFlowDTO] = []

        if let componentsMatch = try? extractComponents(from: buffer) {
            components = componentsMatch
        }

        if let flowsMatch = try? extractFlows(from: buffer) {
            flows = flowsMatch
        }

        guard !components.isEmpty || !flows.isEmpty else {
            return nil
        }

        return PartialResults(
            components: components,
            flows: flows
        )
    }

    /// Parse final complete buffer
    func parseFinalBuffer(_ buffer: String) throws -> VisionAnalysisOutput {
        let parser = AnthropicJSONParser()
        return try parser.parse(buffer, attempt: 0, maxAttempts: 3)
    }

    // MARK: - Private Helpers

    private func extractComponents(
        from text: String
    ) throws -> [VisionAnalysisOutput.ComponentDTO] {
        let pattern = "\"components\"\\s*:\\s*\\[(.*?)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
              ) else {
            return []
        }

        let json = "[" + (text as NSString)
            .substring(with: match.range(at: 1)) + "]"
        guard let data = json.data(using: .utf8) else {
            return []
        }

        return try JSONDecoder().decode(
            [VisionAnalysisOutput.ComponentDTO].self,
            from: data
        )
    }

    private func extractFlows(
        from text: String
    ) throws -> [VisionAnalysisOutput.UserFlowDTO] {
        let pattern = "\"userFlows\"\\s*:\\s*\\[(.*?)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
              ) else {
            return []
        }

        let json = "[" + (text as NSString)
            .substring(with: match.range(at: 1)) + "]"
        guard let data = json.data(using: .utf8) else {
            return []
        }

        return try JSONDecoder().decode(
            [VisionAnalysisOutput.UserFlowDTO].self,
            from: data
        )
    }
}

