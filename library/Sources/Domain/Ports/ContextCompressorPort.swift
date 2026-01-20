import Foundation

/// Port for context compression using various techniques.
///
/// Compression techniques:
/// - **Semantic**: Remove redundant information while preserving meaning
/// - **MetaToken**: Replace repeated patterns with meta-tokens
/// - **Contextual**: Enrich chunks with BM25 context before embedding
/// - **TokenSkip**: Skip redundant reasoning tokens in CoT
///
/// Used for:
/// - Fitting large context into small windows (Apple Intelligence 4K)
/// - Cost optimization (reduce token usage)
/// - Quality preservation (maintain semantic meaning)
public protocol ContextCompressorPort: Sendable {
    /// Compress context to target ratio
    ///
    /// - Parameters:
    ///   - text: Text to compress
    ///   - targetRatio: Target compression ratio (0.0-1.0)
    /// - Returns: Compressed context with metadata
    /// - Throws: CompressionError if compression fails
    func compress(
        _ text: String,
        targetRatio: Double
    ) async throws -> CompressedContext

    /// Decompress context back to original form
    ///
    /// - Parameter compressed: Compressed context
    /// - Returns: Decompressed text
    /// - Throws: CompressionError if decompression fails
    func decompress(_ compressed: CompressedContext) async throws -> String

    /// Compression technique used by this compressor
    var technique: CompressionTechnique { get }
}
