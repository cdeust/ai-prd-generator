import Foundation
import Domain

/// Manages latent state evolution across TRM iterations
///
/// Tracks refinement state history and provides utilities for:
/// - Aggregating insights across multiple iterations
/// - Pruning redundant information
/// - Maintaining working memory
///
/// **Usage:**
/// ```swift
/// let tracker = TRMStateTracker()
/// let aggregated = tracker.aggregateInsights(from: allStates)
/// let pruned = tracker.pruneRedundancies(in: currentState)
/// ```
public struct TRMStateTracker: Sendable {
    public init() {}

    // MARK: - Public Methods

    /// Aggregate insights from multiple refinement states
    ///
    /// Combines insights across iterations, removing duplicates
    /// and maintaining the most relevant information.
    ///
    /// - Parameter states: Collection of refinement states
    /// - Returns: Aggregated insights
    public func aggregateInsights(
        from states: [RefinementState]
    ) -> [String] {
        let allInsights = states.flatMap { $0.workingMemory }
        return removeDuplicates(from: allInsights)
    }

    /// Prune redundant information from state
    ///
    /// Removes duplicate or highly similar items from all state arrays,
    /// keeping the most informative entries.
    ///
    /// - Parameter state: Refinement state to prune
    /// - Returns: Pruned refinement state
    public func pruneRedundancies(
        in state: RefinementState
    ) -> RefinementState {
        return RefinementState(
            workingMemory: removeDuplicates(from: state.workingMemory),
            errorCorrections: removeDuplicates(from: state.errorCorrections),
            hypotheses: removeDuplicates(from: state.hypotheses),
            uncertainties: removeDuplicates(from: state.uncertainties),
            evidenceGathered: removeDuplicates(from: state.evidenceGathered)
        )
    }

    // MARK: - Private Methods

    /// Remove duplicate strings (case-insensitive)
    ///
    /// - Parameter items: Array of strings
    /// - Returns: Deduplicated array
    private func removeDuplicates(from items: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for item in items {
            let normalized = item.lowercased().trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            if !seen.contains(normalized) {
                seen.insert(normalized)
                result.append(item)
            }
        }

        return result
    }
}
