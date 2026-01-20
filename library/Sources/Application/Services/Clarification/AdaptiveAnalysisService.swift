import Foundation

/// Service for executing adaptive analysis with confidence-based retry
///
/// Professional retry logic: increases temperature if confidence is low
public actor AdaptiveAnalysisService {
    private let temperatureStrategy: AdaptiveTemperatureStrategy

    public init(temperatureStrategy: AdaptiveTemperatureStrategy = AdaptiveTemperatureStrategy()) {
        self.temperatureStrategy = temperatureStrategy
    }

    /// Execute analysis with adaptive temperature retry
    ///
    /// - Parameters:
    ///   - analyzer: Function that performs analysis at given temperature
    ///   - extractConfidence: Function to extract confidence from result
    /// - Returns: Adaptive analysis result with best attempt
    /// - Throws: Error if all attempts fail
    public func executeWithRetry<T>(
        analyzer: @Sendable (Double) async throws -> T,
        extractConfidence: @Sendable (T) -> Double
    ) async throws -> AdaptiveAnalysisResult<T> {
        var currentTemperature = temperatureStrategy.initialTemperature()
        var attemptNumber = 1
        var lastResult: T?

        while let temperature = attemptNumber == 1
            ? currentTemperature
            : temperatureStrategy.nextTemperature(
                currentTemperature: currentTemperature,
                confidence: lastResult.map(extractConfidence) ?? 0.0,
                attemptNumber: attemptNumber
            ) {

            let result = try await analyzer(temperature)
            let confidence = extractConfidence(result)

            lastResult = result

            if temperatureStrategy.isConfidenceAcceptable(confidence) {
                return AdaptiveAnalysisResult(
                    value: result,
                    confidence: confidence,
                    temperature: temperature,
                    attemptNumber: attemptNumber,
                    reasoning: formatSuccessReasoning(confidence: confidence, temperature: temperature)
                )
            }

            currentTemperature = temperature
            attemptNumber += 1
        }

        guard let finalResult = lastResult else {
            throw AdaptiveAnalysisError.noAttemptsCompleted
        }

        let finalConfidence = extractConfidence(finalResult)
        return AdaptiveAnalysisResult(
            value: finalResult,
            confidence: finalConfidence,
            temperature: currentTemperature,
            attemptNumber: attemptNumber - 1,
            reasoning: formatMaxRetriesReasoning(confidence: finalConfidence)
        )
    }

    private func formatSuccessReasoning(confidence: Double, temperature: Double) -> String {
        "Acceptable confidence (\(String(format: "%.2f", confidence))) achieved at temperature \(String(format: "%.2f", temperature))"
    }

    private func formatMaxRetriesReasoning(confidence: Double) -> String {
        "Max retries reached. Using best available result (confidence: \(String(format: "%.2f", confidence)))"
    }
}
