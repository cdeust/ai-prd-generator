import Foundation

/// Complexity scoring for the project
/// Following Single Responsibility Principle - represents complexity metrics
public struct ComplexityScore: Sendable, Codable {
    public let overall: Int // 1-10
    public let technical: Int
    public let architectural: Int
    public let integration: Int
    public let reasoning: String

    public init(
        overall: Int,
        technical: Int,
        architectural: Int,
        integration: Int,
        reasoning: String
    ) {
        self.overall = overall
        self.technical = technical
        self.architectural = architectural
        self.integration = integration
        self.reasoning = reasoning
    }
}
