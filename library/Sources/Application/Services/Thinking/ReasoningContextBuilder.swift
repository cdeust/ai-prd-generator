import Foundation
import Domain

/// Builds and maintains reasoning context across multi-step chains
///
/// **Reusable Component:** Any multi-step reasoning system needs to:
/// - Accumulate context from completed steps
/// - Extract follow-up questions from reasoning outputs
/// - Maintain structured history for synthesis
///
/// Following Single Responsibility: Context management for reasoning chains
public struct ReasoningContextBuilder: Sendable {
    public init() {}

    /// Append reasoning hop to existing context
    ///
    /// - Parameters:
    ///   - current: Current accumulated context
    ///   - hop: Reasoning hop to append
    /// - Returns: Updated context with hop conclusion added
    public func appendHop(_ current: String, hop: ReasoningHop) -> String {
        """
        \(current)

        ## Step \(hop.hopNumber + 1): \(hop.question)
        \(hop.conclusion)
        """
    }

    /// Extract unresolved questions from reasoning hop
    ///
    /// Identifies:
    /// - Explicit questions in observations (contains "?")
    /// - Assumptions requiring validation
    ///
    /// - Parameter hop: Reasoning hop to analyze
    /// - Returns: Up to 2 most critical unresolved questions
    public func extractUnresolvedQuestions(from hop: ReasoningHop) -> [String] {
        var questions: [String] = []

        // Explicit questions in observations
        for thought in hop.thoughts where thought.type == .observation {
            if thought.content.contains("?") {
                questions.append(thought.content)
            }
        }

        // High-uncertainty assumptions needing validation
        for assumption in hop.assumptions where assumption.requiresValidation {
            questions.append("Validate: \(assumption.description)")
        }

        return Array(questions.prefix(2))
    }
}
