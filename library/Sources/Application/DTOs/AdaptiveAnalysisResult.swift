import Foundation

/// Result of adaptive analysis with retry capability
public struct AdaptiveAnalysisResult<T> {
    public let value: T
    public let confidence: Double
    public let temperature: Double
    public let attemptNumber: Int
    public let reasoning: String

    public init(
        value: T,
        confidence: Double,
        temperature: Double,
        attemptNumber: Int,
        reasoning: String
    ) {
        self.value = value
        self.confidence = confidence
        self.temperature = temperature
        self.attemptNumber = attemptNumber
        self.reasoning = reasoning
    }
}
