import Foundation

/// Validation plan with prioritized assumptions
/// Following Single Responsibility: Organizes validation priorities only
public struct ValidationPlan: Sendable {
    public let priority1: [TrackedAssumption] // Critical
    public let priority2: [TrackedAssumption] // High impact
    public let priority3: [TrackedAssumption] // Has dependents
    public let priority4: [TrackedAssumption] // Others

    public init(
        priority1: [TrackedAssumption],
        priority2: [TrackedAssumption],
        priority3: [TrackedAssumption],
        priority4: [TrackedAssumption]
    ) {
        self.priority1 = priority1
        self.priority2 = priority2
        self.priority3 = priority3
        self.priority4 = priority4
    }
}
