import Foundation

/// Detected architecture pattern with confidence
/// Following Single Responsibility Principle - represents detected pattern
public struct DetectedArchitecturePattern: Sendable, Codable {
    public let pattern: ArchitecturePattern
    public let confidence: Double
    public let evidence: [String]

    public init(
        pattern: ArchitecturePattern,
        confidence: Double,
        evidence: [String]
    ) {
        self.pattern = pattern
        self.confidence = confidence
        self.evidence = evidence
    }
}
