import Foundation

/// Compressed context with metadata
public struct CompressedContext: Sendable, Codable {
    public let id: UUID
    public let compressedText: String
    public let originalTokenCount: Int
    public let compressedTokenCount: Int
    public let compressionRatio: Double
    public let technique: CompressionTechnique
    public let metadata: CompressionMetadata

    public init(
        id: UUID = UUID(),
        compressedText: String,
        originalTokenCount: Int,
        compressedTokenCount: Int,
        compressionRatio: Double,
        technique: CompressionTechnique,
        metadata: CompressionMetadata
    ) {
        self.id = id
        self.compressedText = compressedText
        self.originalTokenCount = originalTokenCount
        self.compressedTokenCount = compressedTokenCount
        self.compressionRatio = compressionRatio
        self.technique = technique
        self.metadata = metadata
    }

    public var compressionPercentage: Double {
        (1.0 - compressionRatio) * 100.0
    }
}
