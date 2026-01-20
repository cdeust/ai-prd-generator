import Foundation

/// A UI pattern detected in mockup analysis
public struct DetectedUIPattern: Sendable, Codable {
    public let type: String
    public let pattern: String
    public let confidence: Double

    public init(
        type: String,
        pattern: String,
        confidence: Double
    ) {
        self.type = type
        self.pattern = pattern
        self.confidence = confidence
    }
}
