import Foundation

/// Decision to halt or continue TRM iterations
/// Following Single Responsibility: Represent halting logic outcome
public struct HaltingDecision: Sendable {
    public let shouldHalt: Bool
    public let reason: HaltingReason
    public let confidence: Double
    public let iterationNumber: Int

    public init(
        shouldHalt: Bool,
        reason: HaltingReason,
        confidence: Double,
        iterationNumber: Int
    ) {
        self.shouldHalt = shouldHalt
        self.reason = reason
        self.confidence = confidence
        self.iterationNumber = iterationNumber
    }

    /// Halting reason categorization
    public enum HaltingReason: String, Sendable {
        case confidenceThresholdMet
        case maxIterationsReached
        case convergenceDetected
        case oscillationDetected
        case diminishingReturns
        case earlySuccess
        case continueRefining

        public var description: String {
            switch self {
            case .confidenceThresholdMet:
                return "Quality target met"
            case .maxIterationsReached:
                return "Maximum iterations reached (safety limit)"
            case .convergenceDetected:
                return "Convergence detected (statistical evidence)"
            case .oscillationDetected:
                return "Oscillation detected (unstable trajectory)"
            case .diminishingReturns:
                return "Diminishing returns detected (flattening slope)"
            case .earlySuccess:
                return "Early success with very high confidence"
            case .continueRefining:
                return "Continue refining"
            }
        }
    }
}
