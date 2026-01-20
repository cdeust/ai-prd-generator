import Foundation

/// Adaptive threshold based on historical data
public struct AdaptiveThreshold: Sendable {
    public let threshold: Double
    public let confidence: Double // How confident we are in this threshold (0-1)
    public let source: ThresholdSource
    public let sampleSize: Int

    public enum ThresholdSource: Sendable {
        case historicalData
        case `default`
    }
}
