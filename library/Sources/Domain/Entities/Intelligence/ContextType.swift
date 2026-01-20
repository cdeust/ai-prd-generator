import Foundation

/// Type of context for an LLM interaction
/// Tracks whether this is initial, refinement, or retry
public enum ContextType: String, Sendable, Codable, CaseIterable {
    case initial = "initial"
    case codebaseEnriched = "codebase_enriched"
    case refinement = "refinement"
    case retry = "retry"
}
