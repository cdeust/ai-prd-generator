import Foundation

/// Scaling breakpoint identification
/// Following Single Responsibility Principle - represents scaling threshold
public struct ScalingBreakpoint: Identifiable, Sendable, Codable {
    public let id: UUID
    public let metric: String
    public let threshold: String
    public let impact: String
    public let mitigation: String

    public init(
        id: UUID = UUID(),
        metric: String,
        threshold: String,
        impact: String,
        mitigation: String
    ) {
        self.id = id
        self.metric = metric
        self.threshold = threshold
        self.impact = impact
        self.mitigation = mitigation
    }
}
