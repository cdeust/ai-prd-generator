import Foundation

/// Compression metadata with detailed performance metrics
public struct CompressionMetadata: Sendable, Codable {
    /// Compression technique used
    public let technique: CompressionTechnique

    /// When compression occurred
    public let compressedAt: Date

    /// Original token count before compression
    public let originalTokens: Int

    /// Compressed token count after compression
    public let compressedTokens: Int

    /// Compression ratio (compressedTokens / originalTokens)
    public let compressionRatio: Double

    /// Quality score (0.0-1.0) - semantic preservation
    public let qualityScore: Double

    /// Key concepts preserved during compression
    public let preservedConcepts: [String]?

    /// Technique-specific parameters and metrics
    public let parameters: [String: String]

    public init(
        technique: CompressionTechnique,
        compressedAt: Date = Date(),
        originalTokens: Int,
        compressedTokens: Int,
        compressionRatio: Double,
        qualityScore: Double,
        preservedConcepts: [String]? = nil,
        parameters: [String: String] = [:]
    ) {
        self.technique = technique
        self.compressedAt = compressedAt
        self.originalTokens = originalTokens
        self.compressedTokens = compressedTokens
        self.compressionRatio = compressionRatio
        self.qualityScore = qualityScore
        self.preservedConcepts = preservedConcepts
        self.parameters = parameters
    }

    /// Compression percentage (1.0 - ratio) * 100
    public var compressionPercentage: Double {
        (1.0 - compressionRatio) * 100.0
    }

    /// Tokens saved
    public var tokensSaved: Int {
        originalTokens - compressedTokens
    }
}
