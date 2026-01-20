import Foundation

/// Robust JSON parser with multiple fallback strategies for Anthropic responses
struct AnthropicJSONParser: Sendable {
    func parse(
        _ responseText: String,
        attempt: Int,
        maxAttempts: Int
    ) throws -> VisionAnalysisOutput {
        if let output = try? parseDirectJSON(responseText) {
            return output
        }

        if let output = try? parseMarkdownJSON(responseText) {
            return output
        }

        if let output = try? extractEmbeddedJSON(responseText) {
            return output
        }

        if attempt == maxAttempts - 1 {
            if let output = try? repairAndParseJSON(responseText) {
                return output
            }
        }

        throw AnthropicParsingError.failedAfterAllStrategies(attempt: attempt + 1)
    }

    private func parseDirectJSON(_ text: String) throws -> VisionAnalysisOutput {
        guard let data = text.data(using: .utf8) else {
            throw AnthropicParsingError.invalidUTF8
        }

        return try JSONDecoder().decode(VisionAnalysisOutput.self, from: data)
    }

    private func parseMarkdownJSON(_ text: String) throws -> VisionAnalysisOutput {
        let pattern = "```json\\s*([\\s\\S]*?)\\s*```"
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsRange = NSRange(text.startIndex..., in: text)

        guard let match = regex.firstMatch(in: text, range: nsRange),
              let jsonRange = Range(match.range(at: 1), in: text) else {
            throw AnthropicParsingError.noMarkdownCodeBlock
        }

        let jsonString = String(text[jsonRange])
        return try parseDirectJSON(jsonString)
    }

    private func extractEmbeddedJSON(_ text: String) throws -> VisionAnalysisOutput {
        guard let startIndex = text.range(of: "{")?.lowerBound,
              let endIndex = text.range(of: "}", options: .backwards)?.upperBound else {
            throw AnthropicParsingError.noJSONBrackets
        }

        let jsonString = String(text[startIndex..<endIndex])
        return try parseDirectJSON(jsonString)
    }

    private func repairAndParseJSON(_ text: String) throws -> VisionAnalysisOutput {
        var repaired = text

        repaired = removeTrailingCommas(from: repaired)
        repaired = fixUnescapedQuotes(in: repaired)
        repaired = fixMissingCommas(in: repaired)

        return try parseDirectJSON(repaired)
    }

    private func removeTrailingCommas(from text: String) -> String {
        text.replacingOccurrences(
            of: ",\\s*([}\\]])",
            with: "$1",
            options: .regularExpression
        )
    }

    private func fixUnescapedQuotes(in text: String) -> String {
        text
    }

    private func fixMissingCommas(in text: String) -> String {
        text.replacingOccurrences(
            of: "}\\s*{",
            with: "},{",
            options: .regularExpression
        )
    }
}


