import Foundation

/// Port for structured thinking/reasoning
/// Domain defines the interface, Application implements
public protocol ThinkingPort: Sendable {
    /// Generate structured thought chain
    func think(about input: String) async throws -> ThoughtChain

    /// Perform reasoning with context
    func reason(with context: [String: String]) async throws -> ReasoningResult
}
