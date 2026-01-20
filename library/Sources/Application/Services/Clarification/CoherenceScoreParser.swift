import Foundation

/// Parses LLM responses containing coherence and effectiveness scores
struct CoherenceScoreParser: Sendable {

    func parseScores(from response: String, questionCount: Int) -> [QuestionScore] {
        var scores: [QuestionScore] = []
        let scorePattern = "<score index=\"(\\d+)\">(.*?)</score>"

        guard let regex = try? NSRegularExpression(pattern: scorePattern, options: .dotMatchesLineSeparators) else {
            return defaultScores(count: questionCount, reasoning: "Parse error")
        }

        let range = NSRange(response.startIndex..., in: response)
        let matches = regex.matches(in: response, options: [], range: range)

        for match in matches {
            guard let scoreRange = Range(match.range(at: 2), in: response) else { continue }
            let scoreBlock = String(response[scoreRange])
            scores.append(parseScoreBlock(scoreBlock))
        }

        // Pad with defaults if parsing failed
        while scores.count < questionCount {
            scores.append(QuestionScore(coherence: 0.5, effectiveness: 0.5, reasoning: "Not scored"))
        }

        return scores
    }

    private func parseScoreBlock(_ block: String) -> QuestionScore {
        let coherence = extractDouble(from: block, tag: "coherence") ?? 0.5
        let effectiveness = extractDouble(from: block, tag: "effectiveness") ?? 0.5
        let reasoning = extractString(from: block, tag: "reasoning") ?? ""
        return QuestionScore(coherence: coherence, effectiveness: effectiveness, reasoning: reasoning)
    }

    private func defaultScores(count: Int, reasoning: String) -> [QuestionScore] {
        Array(repeating: QuestionScore(coherence: 0.5, effectiveness: 0.5, reasoning: reasoning), count: count)
    }

    private func extractDouble(from xml: String, tag: String) -> Double? {
        guard let value = extractString(from: xml, tag: tag) else { return nil }
        return Double(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func extractString(from xml: String, tag: String) -> String? {
        let pattern = "<\(tag)>(.*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
              let match = regex.firstMatch(in: xml, options: [], range: NSRange(xml.startIndex..., in: xml)),
              let range = Range(match.range(at: 1), in: xml) else {
            return nil
        }
        return String(xml[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
