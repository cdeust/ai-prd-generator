import Foundation

/// Base reasoning strategies that can be enhanced
public enum BaseStrategy: Sendable, Hashable, Equatable {
    case chainOfThought
    case reflexion
    case planAndSolve
    case verifiedReasoning
}
