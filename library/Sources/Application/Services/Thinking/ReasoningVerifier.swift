import Foundation
import Domain

/// Verifies reasoning for hallucinations, contradictions, and logical errors
/// Following Single Responsibility: Only verifies reasoning validity
public struct ReasoningVerifier: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Verify reasoning hop for errors and hallucinations
    public func verify(
        hop: ReasoningHop,
        originalContext: String
    ) async throws -> VerificationResult {
        // Multi-stage verification
        let contextGrounding = try await checkContextGrounding(hop: hop, context: originalContext)
        let logicalConsistency = checkLogicalConsistency(hop: hop)
        let contradictions = detectContradictions(hop: hop)
        let hallucinationRisk = try await assessHallucinationRisk(hop: hop, context: originalContext)

        var issues: [String] = []
        var severity: VerificationSeverity = .valid

        // Aggregate issues
        if !contextGrounding.isGrounded {
            issues.append("Not grounded in context: \(contextGrounding.reason)")
            severity = .critical
        }

        if !logicalConsistency.isConsistent {
            issues.append("Logical inconsistency: \(logicalConsistency.reason)")
            severity = max(severity, .major)
        }

        if !contradictions.isEmpty {
            issues.append(contentsOf: contradictions.map { "Contradiction: \($0)" })
            severity = max(severity, .major)
        }

        if hallucinationRisk.risk > 0.5 {
            issues.append("High hallucination risk: \(hallucinationRisk.reason)")
            severity = max(severity, .major)
        }

        return VerificationResult(
            isValid: issues.isEmpty,
            severity: severity,
            issues: issues,
            contextGroundingScore: contextGrounding.score,
            hallucinationRisk: hallucinationRisk.risk
        )
    }

    // MARK: - Verification Checks

    /// Check if reasoning is grounded in provided context
    private func checkContextGrounding(
        hop: ReasoningHop,
        context: String
    ) async throws -> GroundingCheck {
        let prompt = """
        Verify if the following conclusion is grounded in the provided context.

        <context>
        \(context)
        </context>

        <conclusion>
        \(hop.conclusion)
        </conclusion>

        <reasoning>
        \(hop.thoughts.map(\.content).joined(separator: "\n"))
        </reasoning>

        Answer:
        1. Is the conclusion supported by the context? (YES/NO)
        2. Grounding score (0.0-1.0): How well is it supported?
        3. If NO or low score, explain why

        Format:
        GROUNDED: [YES/NO]
        SCORE: [0.0-1.0]
        REASON: [explanation if not grounded]
        """

        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.0
        )

        return parseGroundingCheck(response)
    }

    /// Check logical consistency within reasoning
    private func checkLogicalConsistency(hop: ReasoningHop) -> ConsistencyCheck {
        var inconsistencies: [String] = []

        // Check if inferences follow from observations
        let observations = hop.thoughts.filter { $0.type == .observation }
        let inferences = hop.thoughts.filter { $0.type == .inference }

        if !inferences.isEmpty && observations.isEmpty {
            inconsistencies.append("Inferences made without observations")
        }

        // Check if conclusion follows from inferences
        if hop.thoughts.filter({ $0.type == .conclusion }).isEmpty {
            inconsistencies.append("No conclusion step in reasoning")
        }

        // Check assumption validity
        for assumption in hop.assumptions where assumption.confidence < 0.3 {
            inconsistencies.append("Very low confidence assumption: \(assumption.description)")
        }

        return ConsistencyCheck(
            isConsistent: inconsistencies.isEmpty,
            reason: inconsistencies.joined(separator: "; ")
        )
    }

    /// Detect contradictions within reasoning
    private func detectContradictions(hop: ReasoningHop) -> [String] {
        var contradictions: [String] = []

        let allStatements = hop.thoughts.map(\.content) + [hop.conclusion]

        // Simple contradiction detection (can be enhanced with embeddings)
        let negationWords = ["not", "no", "never", "cannot", "isn't", "aren't", "won't"]

        for (i, statement1) in allStatements.enumerated() {
            for (j, statement2) in allStatements.enumerated() where j > i {
                // Check for direct contradictions
                let hasNegation1 = negationWords.contains { statement1.lowercased().contains($0) }
                let hasNegation2 = negationWords.contains { statement2.lowercased().contains($0) }

                if hasNegation1 != hasNegation2 {
                    let words1 = Set(statement1.lowercased().split(separator: " ").map(String.init))
                    let words2 = Set(statement2.lowercased().split(separator: " ").map(String.init))
                    let overlap = words1.intersection(words2).count

                    if overlap > 5 { // Significant overlap with opposite polarity
                        contradictions.append("Potential contradiction between steps \(i+1) and \(j+1)")
                    }
                }
            }
        }

        return contradictions
    }

    /// Assess hallucination risk
    private func assessHallucinationRisk(
        hop: ReasoningHop,
        context: String
    ) async throws -> HallucinationAssessment {
        let prompt = """
        Assess the risk of hallucination in this reasoning.

        <provided_context>
        \(context)
        </provided_context>

        <conclusion>
        \(hop.conclusion)
        </conclusion>

        Check for:
        1. Specific claims not in context (hallucinated facts)
        2. Invented technical details
        3. Overconfident statements without evidence
        4. Fabricated relationships or causality

        Rate hallucination risk:
        - 0.0-0.2: Low risk (grounded)
        - 0.3-0.5: Medium risk (some unsupported claims)
        - 0.6-1.0: High risk (likely hallucinations)

        Format:
        RISK: [0.0-1.0]
        REASON: [explanation]
        SPECIFIC_ISSUES: [list any hallucinated content]
        """

        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.0
        )

        return parseHallucinationAssessment(response)
    }

    // MARK: - Parsing Helpers

    private func parseGroundingCheck(_ response: String) -> GroundingCheck {
        let isGrounded = response.contains("GROUNDED: YES")
        var score = 0.5

        if let scoreMatch = response.range(of: #"SCORE:\s*([0-9.]+)"#, options: .regularExpression) {
            let scoreText = response[scoreMatch].replacingOccurrences(of: "SCORE:", with: "").trimmingCharacters(in: .whitespaces)
            score = Double(scoreText) ?? 0.5
        }

        var reason = ""
        if let reasonMatch = response.range(of: #"REASON:\s*(.+)"#, options: .regularExpression) {
            reason = String(response[reasonMatch]).replacingOccurrences(of: "REASON:", with: "").trimmingCharacters(in: .whitespaces)
        }

        return GroundingCheck(
            isGrounded: isGrounded && score > 0.6,
            score: score,
            reason: reason
        )
    }

    private func parseHallucinationAssessment(_ response: String) -> HallucinationAssessment {
        var risk = 0.5

        if let riskMatch = response.range(of: #"RISK:\s*([0-9.]+)"#, options: .regularExpression) {
            let riskText = response[riskMatch].replacingOccurrences(of: "RISK:", with: "").trimmingCharacters(in: .whitespaces)
            risk = Double(riskText) ?? 0.5
        }

        var reason = ""
        if let reasonMatch = response.range(of: #"REASON:\s*(.+)"#, options: .regularExpression) {
            reason = String(response[reasonMatch]).replacingOccurrences(of: "REASON:", with: "").trimmingCharacters(in: .whitespaces)
        }

        return HallucinationAssessment(risk: risk, reason: reason)
    }
}

