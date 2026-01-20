import Foundation
import Domain

/// Parses structured Chain-of-Thought responses with XML tags
/// Following Single Responsibility: Only parses structured reasoning responses
public struct StructuredCoTParser: Sendable {

    /// Parse structured CoT response into thought chain
    public func parse(_ response: String) -> ParsedReasoning {
        let thoughts = extractThoughts(from: response)
        let assumptions = extractAssumptions(from: response)
        let inferences = extractInferences(from: response)
        let conclusion = extractConclusion(from: response)
        let confidence = extractConfidence(from: response)

        return ParsedReasoning(
            thoughts: thoughts,
            assumptions: assumptions,
            inferences: inferences,
            conclusion: conclusion,
            confidence: confidence,
            rawResponse: response
        )
    }

    // MARK: - Private Extraction Methods

    private func extractThoughts(from response: String) -> [Thought] {
        var thoughts: [Thought] = []
        var stepCounter = 0

        // Extract phase-based thoughts
        let phases = [
            ("phase1_understanding", ThoughtType.observation),
            ("phase2_decomposition", ThoughtType.analysis),
            ("phase3_analysis", ThoughtType.analysis),
            ("phase4_synthesis", ThoughtType.inference),
            ("phase5_conclusion", ThoughtType.conclusion)
        ]

        for (tag, type) in phases {
            if let content = extractContent(between: "<\(tag)>", and: "</\(tag)>", in: response) {
                let cleaned = cleanContent(content)
                if !cleaned.isEmpty {
                    thoughts.append(Thought(
                        id: UUID(),
                        content: cleaned,
                        step: stepCounter,
                        type: type
                    ))
                    stepCounter += 1
                }
            }
        }

        // If no structured phases found, fall back to paragraph parsing
        if thoughts.isEmpty {
            thoughts = parseParagraphs(response)
        }

        return thoughts
    }

    private func extractAssumptions(from response: String) -> [Assumption] {
        let pattern = "ASSUMPTION:\\s*([^\\n]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let nsRange = NSRange(response.startIndex..., in: response)
        let matches = regex.matches(in: response, options: [], range: nsRange)

        return matches.compactMap { match in
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: response) else {
                return nil
            }

            let assumptionText = String(response[range]).trimmingCharacters(in: .whitespaces)
            let confidence = inferAssumptionConfidence(from: assumptionText)

            return Assumption(
                id: UUID(),
                description: assumptionText,
                confidence: confidence,
                requiresValidation: confidence < 0.7,
                validationMethod: confidence < 0.7 ? "verify with domain expert" : nil
            )
        }
    }

    private func extractInferences(from response: String) -> [String] {
        let patterns = ["INFERENCE:", "THEREFORE:"]
        var inferences: [String] = []

        for pattern in patterns {
            let parts = response.components(separatedBy: pattern)
            for (index, part) in parts.enumerated() where index > 0 {
                let inference = part
                    .components(separatedBy: "\n")
                    .first?
                    .trimmingCharacters(in: .whitespaces) ?? ""

                if !inference.isEmpty {
                    inferences.append(inference)
                }
            }
        }

        return inferences
    }

    private func extractConclusion(from response: String) -> String {
        // Try to extract from CONCLUSION: marker
        if let conclusionContent = extractContent(after: "CONCLUSION:", in: response) {
            return cleanContent(conclusionContent)
        }

        // Try to extract from phase5 tag
        if let phaseContent = extractContent(between: "<phase5_conclusion>", and: "</phase5_conclusion>", in: response) {
            return cleanContent(phaseContent)
        }

        // Fall back to last meaningful paragraph
        let paragraphs = response
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 20 }

        return paragraphs.last ?? "No conclusion found"
    }

    private func extractConfidence(from response: String) -> Double {
        let lowerResponse = response.lowercased()

        // Explicit confidence markers
        if lowerResponse.contains("confidence: high") || lowerResponse.contains("high confidence") {
            return 0.9
        }
        if lowerResponse.contains("confidence: medium") || lowerResponse.contains("medium confidence") {
            return 0.7
        }
        if lowerResponse.contains("confidence: low") || lowerResponse.contains("low confidence") {
            return 0.4
        }

        // Inference from language
        let highConfidenceTerms = ["certain", "definitely", "clearly", "undoubtedly", "without doubt"]
        let lowConfidenceTerms = ["uncertain", "unclear", "possibly", "might", "could", "perhaps"]
        let mediumConfidenceTerms = ["likely", "probably", "suggests", "indicates"]

        let highCount = highConfidenceTerms.filter { lowerResponse.contains($0) }.count
        let lowCount = lowConfidenceTerms.filter { lowerResponse.contains($0) }.count
        let mediumCount = mediumConfidenceTerms.filter { lowerResponse.contains($0) }.count

        if highCount > lowCount && highCount > mediumCount {
            return 0.85
        }
        if lowCount > highCount {
            return 0.5
        }
        if mediumCount > 0 {
            return 0.7
        }

        return 0.65 // Default moderate confidence
    }

    // MARK: - Helper Methods

    private func extractContent(between startTag: String, and endTag: String, in text: String) -> String? {
        guard let startRange = text.range(of: startTag),
              let endRange = text.range(of: endTag, range: startRange.upperBound..<text.endIndex) else {
            return nil
        }

        let content = text[startRange.upperBound..<endRange.lowerBound]
        return String(content)
    }

    private func extractContent(after marker: String, in text: String) -> String? {
        guard let range = text.range(of: marker) else {
            return nil
        }

        let afterMarker = text[range.upperBound...]
        return String(afterMarker)
            .components(separatedBy: "\n\n")
            .first?
            .trimmingCharacters(in: .whitespaces)
    }

    private func cleanContent(_ content: String) -> String {
        content
            .replacingOccurrences(of: "\\*\\*[^*]+\\*\\*:", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^\\s*[-*]\\s*", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseParagraphs(_ response: String) -> [Thought] {
        let paragraphs = response
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 10 }

        return paragraphs.enumerated().map { index, content in
            let type = determineThoughtType(from: content, index: index)
            return Thought(
                id: UUID(),
                content: content,
                step: index,
                type: type
            )
        }
    }

    private func determineThoughtType(from content: String, index: Int) -> ThoughtType {
        let lower = content.lowercased()

        if lower.contains("observ") || lower.contains("understand") || index == 0 {
            return .observation
        }
        if lower.contains("conclusion") || lower.contains("therefore") || lower.contains("final") {
            return .conclusion
        }
        if lower.contains("infer") || lower.contains("deduce") || lower.contains("synthesis") {
            return .inference
        }

        return .analysis
    }

    private func inferAssumptionConfidence(from text: String) -> Double {
        let lower = text.lowercased()

        if lower.contains("assuming") || lower.contains("if we assume") {
            return 0.6
        }
        if lower.contains("likely") || lower.contains("probably") {
            return 0.7
        }
        if lower.contains("might") || lower.contains("could") || lower.contains("possibly") {
            return 0.4
        }
        if lower.contains("must") || lower.contains("clearly") {
            return 0.85
        }

        return 0.65
    }
}

