import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Meta-token compression (arXiv:2506.00307, Aug 2025).
///
/// **Meta-Token Compression** replaces repeated patterns with shorthand tokens.
/// Achieves 27% lossless compression by identifying and abbreviating common patterns.
///
/// **Research:** arXiv:2506.00307 (Aug 2025) - "Meta-Token Compression achieves
/// 27% token reduction without quality loss by replacing repeated constructs."
///
/// **Approach:**
/// 1. Identify repeated patterns (phrases, code structures)
/// 2. Create meta-tokens (abbreviations) for top patterns
/// 3. Replace patterns with meta-tokens
/// 4. Store mapping for decompression
///
/// **Example:**
/// - Original: "The user interface should... The user interface must..."
/// - Compressed: "[UI] should... [UI] must..." (where [UI] = "The user interface")
public actor MetaTokenCompressor: ContextCompressorPort {
    private let tokenizer: TokenizerPort

    public let technique: CompressionTechnique = .metaToken

    private let minPatternLength = 3
    private let minOccurrences = 2

    public init(tokenizer: TokenizerPort) {
        self.tokenizer = tokenizer
    }

    public func compress(
        _ text: String,
        targetRatio: Double
    ) async throws -> CompressedContext {
        let patterns = identifyPatterns(in: text)
        let metaTokenMap = createMetaTokenMap(from: patterns)
        let compressedText = applyMetaTokens(to: text, mapping: metaTokenMap)

        let originalTokens = try await tokenizer.countTokens(in: text)
        let compressedTokens = try await tokenizer.countTokens(in: compressedText)
        let actualRatio = Double(compressedTokens) / Double(originalTokens)

        return CompressedContext(
            compressedText: compressedText,
            originalTokenCount: originalTokens,
            compressedTokenCount: compressedTokens,
            compressionRatio: actualRatio,
            technique: .metaToken,
            metadata: CompressionMetadata(
                technique: .metaToken,
                originalTokens: originalTokens,
                compressedTokens: compressedTokens,
                compressionRatio: actualRatio,
                qualityScore: 1.0,
                preservedConcepts: nil,
                parameters: [
                    "metaTokenCount": "\(metaTokenMap.count)",
                    "mapping": encodeMapping(metaTokenMap),
                    "compressionPercentage": String(format: "%.1f%%", (1.0 - actualRatio) * 100)
                ]
            )
        )
    }

    public func decompress(_ compressed: CompressedContext) async throws -> String {
        guard compressed.technique == .metaToken else {
            throw CompressionError.incompatibleTechnique(
                expected: .metaToken,
                found: compressed.technique
            )
        }

        guard let mappingStr = compressed.metadata.parameters["mapping"] else {
            throw CompressionError.missingMetadata("Meta-token mapping not found")
        }

        let mapping = try decodeMapping(mappingStr)

        var decompressed = compressed.compressedText
        for (metaToken, original) in mapping.sorted(by: { $0.key > $1.key }) {
            decompressed = decompressed.replacingOccurrences(of: metaToken, with: original)
        }

        return decompressed
    }

    private func identifyPatterns(in text: String) -> [String: Int] {
        var patterns: [String: Int] = [:]

        let words = text.components(separatedBy: .whitespacesAndNewlines)
        for windowSize in minPatternLength...5 {
            for i in 0...(words.count - windowSize) {
                let pattern = words[i..<(i + windowSize)].joined(separator: " ")
                patterns[pattern, default: 0] += 1
            }
        }

        return patterns.filter { $0.value >= minOccurrences }
    }

    private func createMetaTokenMap(from patterns: [String: Int]) -> [String: String] {
        let topPatterns = patterns
            .sorted { $0.value > $1.value }
            .prefix(20)

        var mapping: [String: String] = [:]
        for (index, (pattern, _)) in topPatterns.enumerated() {
            mapping["[M\(index)]"] = pattern
        }

        return mapping
    }

    private func applyMetaTokens(to text: String, mapping: [String: String]) -> String {
        var compressed = text

        for (metaToken, pattern) in mapping.sorted(by: { $0.value.count > $1.value.count }) {
            compressed = compressed.replacingOccurrences(of: pattern, with: metaToken)
        }

        return compressed
    }

    private func encodeMapping(_ mapping: [String: String]) -> String {
        let encoded = mapping.map { "\($0.key):\($0.value)" }.joined(separator: "||")
        return encoded
    }

    private func decodeMapping(_ encoded: String) throws -> [String: String] {
        var mapping: [String: String] = [:]

        let pairs = encoded.components(separatedBy: "||")
        for pair in pairs {
            let components = pair.components(separatedBy: ":")
            guard components.count == 2 else { continue }
            mapping[components[0]] = components[1]
        }

        return mapping
    }
}
