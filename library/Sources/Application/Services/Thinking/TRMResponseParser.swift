import Foundation
import Domain

/// Parses LLM responses into structured TRM data
///
/// Extracts structured information from LLM responses for:
/// - Latent state updates (NEW_INSIGHTS, ERROR_CORRECTIONS, etc.)
/// - Refined predictions (REFINED_PREDICTION, CONFIDENCE, REASONING)
///
/// Handles malformed responses gracefully with sensible defaults.
///
/// **Usage:**
/// ```swift
/// let parser = TRMResponseParser()
/// let state = parser.parseLatentState(llmResponse)
/// let (prediction, confidence, reasoning) = parser.parseRefinedPrediction(llmResponse)
/// ```
public struct TRMResponseParser: Sendable {
    public init() {}

    // MARK: - Public Methods

    /// Parse latent state update from LLM response
    ///
    /// Extracts structured information from sections:
    /// - NEW_INSIGHTS:
    /// - ERROR_CORRECTIONS:
    /// - REFINED_HYPOTHESES:
    /// - REMAINING_UNCERTAINTIES:
    /// - EVIDENCE:
    ///
    /// - Parameter response: LLM response text
    /// - Returns: Parsed refinement state
    public func parseLatentState(_ response: String) -> RefinementState {
        let insights = extractBulletPoints(
            from: response,
            section: "NEW_INSIGHTS:"
        )
        let corrections = extractBulletPoints(
            from: response,
            section: "ERROR_CORRECTIONS:"
        )
        let hypotheses = extractBulletPoints(
            from: response,
            section: "REFINED_HYPOTHESES:"
        )
        let uncertainties = extractBulletPoints(
            from: response,
            section: "REMAINING_UNCERTAINTIES:"
        )
        let evidence = extractBulletPoints(
            from: response,
            section: "EVIDENCE:"
        )

        return RefinementState(
            workingMemory: insights,
            errorCorrections: corrections,
            hypotheses: hypotheses,
            uncertainties: uncertainties,
            evidenceGathered: evidence
        )
    }

    /// Parse refined prediction from LLM response
    ///
    /// Extracts:
    /// - REFINED_PREDICTION: The improved answer
    /// - CONFIDENCE: Numeric score (0.0-1.0)
    /// - REASONING: Why prediction is better
    ///
    /// - Parameter response: LLM response text
    /// - Returns: Tuple of (prediction, confidence, reasoning)
    public func parseRefinedPrediction(
        _ response: String
    ) -> (prediction: String, confidence: Double, reasoning: String) {
        let prediction = extractSection(
            from: response,
            section: "REFINED_PREDICTION:"
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        let confidenceText = extractSection(
            from: response,
            section: "CONFIDENCE:"
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        let reasoning = extractSection(
            from: response,
            section: "REASONING:"
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse confidence score (default 0.5 if missing/invalid)
        let confidence = Double(confidenceText) ?? 0.5

        return (
            prediction: prediction.isEmpty ? response : prediction,
            confidence: max(0.0, min(1.0, confidence)),
            reasoning: reasoning
        )
    }

    // MARK: - Private Methods

    /// Extract section content between headers
    ///
    /// - Parameters:
    ///   - response: Full response text
    ///   - section: Section header (e.g., "REFINED_PREDICTION:")
    /// - Returns: Section content
    private func extractSection(
        from response: String,
        section: String
    ) -> String {
        let lines = response.components(separatedBy: .newlines)
        var inSection = false
        var sectionContent: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check if we're entering the target section
            if trimmed.hasPrefix(section) {
                inSection = true
                // Include content on same line after header if present
                let afterHeader = String(trimmed.dropFirst(section.count))
                if !afterHeader.isEmpty {
                    sectionContent.append(afterHeader)
                }
                continue
            }

            // Check if we've entered a different section
            if inSection && trimmed.hasSuffix(":") && trimmed.uppercased() == trimmed {
                break
            }

            // Collect content while in section
            if inSection && !trimmed.isEmpty {
                sectionContent.append(line)
            }
        }

        return sectionContent.joined(separator: "\n")
    }

    /// Extract bullet points from section
    ///
    /// - Parameters:
    ///   - response: Full response text
    ///   - section: Section header
    /// - Returns: Array of bullet point content
    private func extractBulletPoints(
        from response: String,
        section: String
    ) -> [String] {
        let sectionText = extractSection(from: response, section: section)
        let lines = sectionText.components(separatedBy: .newlines)

        return lines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.hasPrefix("-") || $0.hasPrefix("•") || $0.hasPrefix("*") }
            .map { line in
                // Remove bullet prefix and trim
                let prefixes = ["-", "•", "*"]
                var cleaned = line
                for prefix in prefixes {
                    if cleaned.hasPrefix(prefix) {
                        cleaned = String(cleaned.dropFirst(prefix.count))
                        break
                    }
                }
                return cleaned.trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
    }
}
