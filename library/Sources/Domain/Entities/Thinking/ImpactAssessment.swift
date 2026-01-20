import Foundation

/// Impact assessment for tracked assumption
/// Following Single Responsibility: Assesses impact only
public struct ImpactAssessment: Sendable {
    public let scope: ImpactScope
    public let severity: ImpactSeverity
    public let affectedComponents: [String]
    public let mitigation: String?

    public init(
        scope: ImpactScope,
        severity: ImpactSeverity,
        affectedComponents: [String],
        mitigation: String?
    ) {
        self.scope = scope
        self.severity = severity
        self.affectedComponents = affectedComponents
        self.mitigation = mitigation
    }
}
