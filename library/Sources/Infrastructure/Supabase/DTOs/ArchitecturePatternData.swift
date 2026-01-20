import Foundation

/// Data transfer object for architecture pattern storage
/// Used by SupabaseCodebaseProjectRecord for architecture pattern data
public struct ArchitecturePatternData: Codable, Sendable {
    public let pattern: String
    public let confidence: Double

    public init(pattern: String, confidence: Double) {
        self.pattern = pattern
        self.confidence = confidence
    }
}
