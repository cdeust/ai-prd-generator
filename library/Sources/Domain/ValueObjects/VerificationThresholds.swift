import Foundation

/// Professional threshold hierarchy for meta-verification system
/// Questions are most critical since they guide entire clarification flow
/// Following Professional Implementation Standards: Data-driven, defensible thresholds
public struct VerificationThresholds: Sendable {
    /// Pre-filter coherence threshold (single-judge, fast check)
    /// Is this question relevant to the product being built?
    /// Threshold: 0.90 (90% confidence required)
    /// Rationale: First-pass filter to eliminate obviously bad questions
    public static let preFilterCoherence: Double = 0.90

    /// Pre-filter effectiveness threshold (single-judge, fast check)
    /// Will this question help build a better PRD?
    /// Threshold: 0.85 (85% confidence required)
    /// Rationale: Slightly more lenient than coherence, measures practical value
    public static let preFilterEffectiveness: Double = 0.85

    /// Question verification threshold (multi-judge consensus)
    /// Do these questions adequately address all gaps?
    /// Threshold: 0.85 (85% consensus required)
    /// Rationale: HIGHEST threshold - questions guide entire flow
    /// Bad questions → Bad answers → Bad PRD (garbage in, garbage out)
    public static let questionVerification: Double = 0.85

    /// PRD verification threshold (multi-judge consensus)
    /// Does the PRD address all requirements and clarifications?
    /// Threshold: 0.75 (75% consensus required)
    /// Rationale: More lenient than questions since questions were already strict
    /// If questions were good, PRD likely good
    public static let prdVerification: Double = 0.75

    /// Low consensus threshold (disagreement detection)
    /// Score variance above this indicates significant judge disagreement
    /// Threshold: 0.25 (variance)
    /// Rationale: Standard deviation > 0.25 on 0-1 scale indicates wide spread
    public static let lowAgreementVariance: Double = 0.25

    /// High confidence threshold
    /// Combined score + confidence must exceed this for "high confidence" designation
    /// Threshold: 0.80 (80%)
    /// Rationale: ISO quality standards typically use 80% for high confidence
    public static let highConfidenceThreshold: Double = 0.80

    /// Minimum score for re-evaluation vs rejection
    /// Scores below this trigger rejection, scores above trigger re-evaluation
    /// Threshold: 0.40 (40%)
    /// Rationale: < 40% consensus indicates fundamental problems, not worth refining
    public static let minimumReEvaluationScore: Double = 0.40

    /// Maximum refinement attempts
    /// Limit refinement loops to prevent infinite cycles
    /// Limit: 2 attempts
    /// Rationale: If verification fails after 2 refinements, problem is systemic
    public static let maxRefinementAttempts: Int = 2

    private init() {}
}
