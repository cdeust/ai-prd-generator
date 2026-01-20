import Foundation
import Domain

/// Detects and removes duplicate clarification questions
/// Single Responsibility: Question deduplication and similarity detection
struct QuestionDeduplicator: Sendable {
    /// Remove questions that are duplicates or very similar to previously asked
    func deduplicateQuestions(
        _ questions: [ClarificationQuestion<String, Int, String>],
        previous: [String]
    ) -> [ClarificationQuestion<String, Int, String>] {
        let previousLower = Set(previous.map { normalizeQuestion($0) })

        let filtered = questions.filter { question in
            let normalized = normalizeQuestion(question.question)
            let isDuplicate = previousLower.contains(normalized) ||
                              previousLower.contains(where: { isSimilar(normalized, $0) })

            if isDuplicate {
                print("🔁 [Dedup] Filtered duplicate: \(question.question.prefix(50))...")
            }
            return !isDuplicate
        }

        print("🧹 [Dedup] Kept \(filtered.count)/\(questions.count) (removed \(questions.count - filtered.count) duplicates)")
        return filtered
    }

    private func normalizeQuestion(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "?", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isSimilar(_ a: String, _ b: String) -> Bool {
        let wordsA = Set(a.split(separator: " ").map { String($0) })
        let wordsB = Set(b.split(separator: " ").map { String($0) })
        let intersection = wordsA.intersection(wordsB)
        let minCount = min(wordsA.count, wordsB.count)
        return minCount > 0 && Double(intersection.count) / Double(minCount) > 0.7
    }
}
