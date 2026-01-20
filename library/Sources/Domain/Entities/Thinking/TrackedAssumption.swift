import Foundation

/// Tracked assumption with validation status
/// Following Single Responsibility: Manages assumption tracking only
public struct TrackedAssumption: Identifiable, Sendable {
    public let id: UUID
    public let statement: String
    public let madeAt: Date
    public let context: String
    public let confidence: Float
    public let category: AssumptionCategory
    public var status: ValidationStatus
    public var evidence: [String]
    public var dependencies: [UUID]
    public var impact: ImpactAssessment?

    public init(
        id: UUID = UUID(),
        statement: String,
        madeAt: Date = Date(),
        context: String,
        confidence: Float,
        category: AssumptionCategory,
        status: ValidationStatus = .unverified,
        evidence: [String] = [],
        dependencies: [UUID] = [],
        impact: ImpactAssessment? = nil
    ) {
        self.id = id
        self.statement = statement
        self.madeAt = madeAt
        self.context = context
        self.confidence = confidence
        self.category = category
        self.status = status
        self.evidence = evidence
        self.dependencies = dependencies
        self.impact = impact
    }
}
