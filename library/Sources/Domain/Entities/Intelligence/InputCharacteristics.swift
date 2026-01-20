import Foundation

/// Characteristics of input that influenced strategy selection
/// Captures problem features for learning
public struct InputCharacteristics: Sendable, Codable {
    public let complexity: String?
    public let ambiguity: String?
    public let domain: String?
    public let userExpertise: String?
    public let hasCodebase: Bool?
    public let hasMockups: Bool?
    public let sectionCount: Int?
    public let requiresExternalInfo: Bool?
    public let needsExploration: Bool?
    public let hasComplexDependencies: Bool?
    public let requiresPrecision: Bool?
    public let benefitsFromIteration: Bool?
    public let requiresVerification: Bool?

    public init(
        complexity: String? = nil,
        ambiguity: String? = nil,
        domain: String? = nil,
        userExpertise: String? = nil,
        hasCodebase: Bool? = nil,
        hasMockups: Bool? = nil,
        sectionCount: Int? = nil,
        requiresExternalInfo: Bool? = nil,
        needsExploration: Bool? = nil,
        hasComplexDependencies: Bool? = nil,
        requiresPrecision: Bool? = nil,
        benefitsFromIteration: Bool? = nil,
        requiresVerification: Bool? = nil
    ) {
        self.complexity = complexity
        self.ambiguity = ambiguity
        self.domain = domain
        self.userExpertise = userExpertise
        self.hasCodebase = hasCodebase
        self.hasMockups = hasMockups
        self.sectionCount = sectionCount
        self.requiresExternalInfo = requiresExternalInfo
        self.needsExploration = needsExploration
        self.hasComplexDependencies = hasComplexDependencies
        self.requiresPrecision = requiresPrecision
        self.benefitsFromIteration = benefitsFromIteration
        self.requiresVerification = requiresVerification
    }
}
