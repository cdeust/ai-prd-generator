import Foundation
import Domain

/// Formats reflection memory for prompts
/// Single Responsibility: Convert reflection history into useful context
public struct ReflectionMemoryFormatter: Sendable {
    public init() {}

    /// Format reflection memory for inclusion in prompts
    public func format(_ memory: [ReflectionEntry]) -> String {
        if memory.isEmpty {
            return ""
        }

        let formattedEntries = memory.enumerated().map { index, entry in
            formatEntry(entry, attemptNumber: index + 1)
        }.joined(separator: "\n\n")

        return """
        <previous_attempts_reflection>
        \(formattedEntries)
        </previous_attempts_reflection>

        Learn from these reflections to improve your approach.
        """
    }

    /// Calculate improvement trajectory
    public func improvementTrajectory(
        _ memory: [ReflectionEntry]
    ) -> [Double] {
        memory.map(\.qualityScore)
    }

    /// Check if approach is improving
    public func isImproving(_ memory: [ReflectionEntry]) -> Bool {
        guard memory.count > 1 else { return false }

        let scores = memory.map(\.qualityScore)
        return scores.last! > scores.first!
    }

    /// Calculate average improvement
    public func averageImprovement(_ memory: [ReflectionEntry]) -> Double {
        guard memory.count > 1 else { return 0.0 }

        let scores = memory.map(\.qualityScore)
        return scores.last! - scores.first!
    }

    // MARK: - Private Methods

    private func formatEntry(
        _ entry: ReflectionEntry,
        attemptNumber: Int
    ) -> String {
        """
        Attempt \(attemptNumber):
        Quality Score: \(String(format: "%.2f", entry.qualityScore))
        Strengths: \(entry.strengths.joined(separator: ", "))
        Weaknesses: \(entry.weaknesses.joined(separator: ", "))
        Improvements: \(entry.suggestedImprovements.joined(separator: ", "))
        """
    }
}
