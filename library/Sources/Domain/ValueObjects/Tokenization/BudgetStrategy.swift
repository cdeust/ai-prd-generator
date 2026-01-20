import Foundation

/// Budget allocation strategy
public enum BudgetStrategy: String, Sendable, Codable {
    /// Full 9-phase pipeline (large context models)
    case fullPipeline

    /// Guided generation only (small context models)
    case guidedGenerationOnly

    /// Hybrid approach
    case hybrid

    /// Adaptive based on content
    case adaptive
}
