import Foundation

/// Problem characteristics for strategy selection
public struct ProblemCharacteristics: Sendable {
    public let needsExploration: Bool
    public let hasMultiplePaths: Bool
    public let hasComplexDependencies: Bool
    public let requiresExternalInfo: Bool
    public let needsPlanning: Bool
    public let hasSequentialSteps: Bool
    public let benefitsFromIteration: Bool
    public let requiresVerification: Bool

    // TRM-specific characteristics
    public let requiresPrecision: Bool
    public let hasHighUncertainty: Bool
    public let benefitsFromTestTimeLearning: Bool
    public let singleAnswerProblem: Bool

    public init(
        needsExploration: Bool,
        hasMultiplePaths: Bool,
        hasComplexDependencies: Bool,
        requiresExternalInfo: Bool,
        needsPlanning: Bool,
        hasSequentialSteps: Bool,
        benefitsFromIteration: Bool,
        requiresVerification: Bool,
        requiresPrecision: Bool,
        hasHighUncertainty: Bool,
        benefitsFromTestTimeLearning: Bool,
        singleAnswerProblem: Bool
    ) {
        self.needsExploration = needsExploration
        self.hasMultiplePaths = hasMultiplePaths
        self.hasComplexDependencies = hasComplexDependencies
        self.requiresExternalInfo = requiresExternalInfo
        self.needsPlanning = needsPlanning
        self.hasSequentialSteps = hasSequentialSteps
        self.benefitsFromIteration = benefitsFromIteration
        self.requiresVerification = requiresVerification
        self.requiresPrecision = requiresPrecision
        self.hasHighUncertainty = hasHighUncertainty
        self.benefitsFromTestTimeLearning = benefitsFromTestTimeLearning
        self.singleAnswerProblem = singleAnswerProblem
    }
}
