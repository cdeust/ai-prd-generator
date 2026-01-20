import Foundation

/// Latent reasoning state in TRM recursive refinement
/// Represents internal "chain-of-thought" memory (z in TRM paper)
/// Following Single Responsibility: Track reasoning evolution
public struct RefinementState: Sendable {
    public let workingMemory: [String]
    public let errorCorrections: [String]
    public let hypotheses: [String]
    public let uncertainties: [String]
    public let evidenceGathered: [String]

    public init(
        workingMemory: [String],
        errorCorrections: [String],
        hypotheses: [String],
        uncertainties: [String],
        evidenceGathered: [String]
    ) {
        self.workingMemory = workingMemory
        self.errorCorrections = errorCorrections
        self.hypotheses = hypotheses
        self.uncertainties = uncertainties
        self.evidenceGathered = evidenceGathered
    }

    /// Create initial empty state
    public static func initial() -> RefinementState {
        RefinementState(
            workingMemory: [],
            errorCorrections: [],
            hypotheses: [],
            uncertainties: [],
            evidenceGathered: []
        )
    }

    /// Update state with new insights
    public func updated(
        addingInsights insights: [String],
        corrections: [String] = [],
        hypotheses: [String] = [],
        uncertainties: [String] = [],
        evidence: [String] = []
    ) -> RefinementState {
        RefinementState(
            workingMemory: workingMemory + insights,
            errorCorrections: errorCorrections + corrections,
            hypotheses: self.hypotheses + hypotheses,
            uncertainties: self.uncertainties + uncertainties,
            evidenceGathered: evidenceGathered + evidence
        )
    }

    /// Check if state has substantial content
    public func hasContent() -> Bool {
        !workingMemory.isEmpty ||
        !errorCorrections.isEmpty ||
        !hypotheses.isEmpty ||
        !evidenceGathered.isEmpty
    }

    /// Count total insights tracked
    public func totalInsights() -> Int {
        workingMemory.count +
        errorCorrections.count +
        hypotheses.count +
        evidenceGathered.count
    }
}
