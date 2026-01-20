import Foundation

/// Professional adaptive temperature strategy based on confidence and reasoning
///
/// Data-driven approach: starts conservative, increases temperature if confidence is low.
/// NOT arbitrary - uses statistical confidence thresholds.
public struct AdaptiveTemperatureStrategy {
    private let minTemperature: Double
    private let maxTemperature: Double
    private let confidenceThreshold: Double
    private let temperatureStep: Double
    private let maxRetries: Int

    public init(
        minTemperature: Double = 0.2,
        maxTemperature: Double = 0.8,
        confidenceThreshold: Double = 0.75,
        temperatureStep: Double = 0.15,
        maxRetries: Int = 3
    ) {
        self.minTemperature = minTemperature
        self.maxTemperature = maxTemperature
        self.confidenceThreshold = confidenceThreshold
        self.temperatureStep = temperatureStep
        self.maxRetries = maxRetries
    }

    /// Calculate next temperature based on current confidence
    ///
    /// Professional approach:
    /// - Start conservative (low temperature = deterministic)
    /// - If confidence < threshold, increase temperature for exploration
    /// - Cap at maxTemperature to avoid incoherence
    ///
    /// - Parameters:
    ///   - currentTemperature: Current temperature value
    ///   - confidence: Analysis confidence (0-1)
    ///   - attemptNumber: Current attempt (1-based)
    /// - Returns: Next temperature to try, or nil if max retries reached
    public func nextTemperature(
        currentTemperature: Double,
        confidence: Double,
        attemptNumber: Int
    ) -> Double? {
        guard attemptNumber < maxRetries else {
            return nil
        }

        if confidence >= confidenceThreshold {
            return currentTemperature
        }

        let nextTemp = currentTemperature + temperatureStep
        return min(nextTemp, maxTemperature)
    }

    /// Get initial temperature for first attempt
    public func initialTemperature() -> Double {
        minTemperature
    }

    /// Check if confidence is acceptable
    public func isConfidenceAcceptable(_ confidence: Double) -> Bool {
        confidence >= confidenceThreshold
    }
}
