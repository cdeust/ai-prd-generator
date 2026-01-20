import Foundation

/// Compression errors
public enum CompressionError: Error, Sendable {
    case compressionFailed(reason: String)
    case decompressionFailed(reason: String)
    case invalidRatio(Double)
    case techniqueNotSupported(CompressionTechnique)
    case qualityThresholdNotMet(actual: Double, required: Double)
    case incompatibleTechnique(expected: CompressionTechnique, found: CompressionTechnique)
    case missingMetadata(String)
}
