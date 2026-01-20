import Foundation

/// Prunes clarifications to fit within context window limits
/// Single Responsibility: Token-aware pruning of clarification history
struct ClarificationPruner: Sendable {
    private let tokenCounter = TokenCounter()

    /// Prune clarifications to fit within context window
    /// Keeps most recent clarifications, drops oldest first
    func pruneClarificationsToFit(
        basePrompt: String,
        clarifications: [(question: String, answer: String)],
        contextWindowSize: Int
    ) -> [(question: String, answer: String)] {
        guard !clarifications.isEmpty else { return [] }

        let safetyMargin = 500
        let baseTokens = tokenCounter.estimateTokens(basePrompt)

        if baseTokens >= contextWindowSize - safetyMargin {
            print("🚨 [ClarificationPruner] BASE PROMPT TOO LARGE: \(baseTokens) tokens (limit: \(contextWindowSize - safetyMargin))")
            return []
        }

        let availableForClarifications = contextWindowSize - safetyMargin - baseTokens
        var includedClarifications: [(question: String, answer: String)] = []
        var currentTokens = 0

        for clarification in clarifications.reversed() {
            let clarificationXML = buildClarificationXML(clarification)
            let tokens = tokenCounter.estimateTokens(clarificationXML)

            if currentTokens + tokens <= availableForClarifications {
                includedClarifications.insert(clarification, at: 0)
                currentTokens += tokens
            } else {
                break
            }
        }

        logPruningResults(
            original: clarifications.count,
            included: includedClarifications.count,
            baseTokens: baseTokens,
            clarificationTokens: currentTokens,
            contextWindowSize: contextWindowSize
        )

        return includedClarifications
    }

    private func buildClarificationXML(_ clarification: (question: String, answer: String)) -> String {
        """
        <clarified>
        <q>\(clarification.question)</q>
        <a>\(clarification.answer)</a>
        </clarified>
        """
    }

    private func logPruningResults(
        original: Int,
        included: Int,
        baseTokens: Int,
        clarificationTokens: Int,
        contextWindowSize: Int
    ) {
        let droppedCount = original - included
        let safetyMargin = 500

        if droppedCount > 0 {
            print("⚠️ [ClarificationPruner] PRUNED \(droppedCount) older clarifications to fit context window")
            print("   📊 Base: \(baseTokens) tokens, Clarifications: \(clarificationTokens) tokens, Total: \(baseTokens + clarificationTokens)/\(contextWindowSize - safetyMargin)")
        } else {
            let totalTokens = baseTokens + clarificationTokens
            print("✅ [ClarificationPruner] All clarifications fit: \(totalTokens)/\(contextWindowSize - safetyMargin) tokens (\(String(format: "%.1f", Double(totalTokens) / Double(contextWindowSize - safetyMargin) * 100))%)")
        }
    }
}
