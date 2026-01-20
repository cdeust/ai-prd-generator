import Foundation

/// Metadata about mockup analysis
public struct AnalysisMetadata: Sendable, Codable, Equatable {
    /// Confidence score (0.0-1.0)
    public let confidence: Double

    /// Model used for analysis
    public let modelName: String

    /// Analysis duration in seconds
    public let durationSeconds: Double

    /// Image dimensions
    public let imageDimensions: ImageDimensions

    /// Additional metadata
    public let additionalInfo: [String: String]

    public init(
        confidence: Double,
        modelName: String,
        durationSeconds: Double,
        imageDimensions: ImageDimensions,
        additionalInfo: [String: String] = [:]
    ) {
        self.confidence = confidence
        self.modelName = modelName
        self.durationSeconds = durationSeconds
        self.imageDimensions = imageDimensions
        self.additionalInfo = additionalInfo
    }
}
