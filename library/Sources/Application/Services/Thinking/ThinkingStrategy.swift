import Foundation

/// Available thinking strategies
///
/// Supports both standalone strategies and composable enhancements.
/// Use `.enhanced()` to apply meta-enhancements like TRM refinement.
public enum ThinkingStrategy: Sendable, Hashable, Equatable {
    // Core reasoning strategies
    case chainOfThought
    case treeOfThoughts
    case graphOfThoughts
    case react
    case reflexion
    case planAndSolve
    case verifiedReasoning
    case recursiveRefinement

    // Prompting strategies
    case zeroShot
    case fewShot([Example])
    case selfConsistency
    case generateKnowledge
    case promptChaining
    case multimodalCoT
    case metaPrompting

    /// Composable enhancement: Apply meta-enhancement to base strategy
    case enhanced(
        baseStrategy: BaseStrategy,
        enhancement: EnhancementType
    )
}
