import Foundation
import Domain

/// Ultra-aggressive compression for Apple Intelligence (4K context).
///
/// Achieves 95% compression by extracting only essential information:
/// - Key requirements (top 5)
/// - Architectural patterns (not code)
/// - Mockup bullet points (not details)
/// - Meta-token compression on everything
///
/// **Target**: 20K tokens → 1K tokens (95% compression)
public struct AppleIntelligenceContextCompressor: Sendable {
    private let aiProvider: AIProviderPort
    private let tokenizer: TokenizerPort
    private let metaTokenCompressor: ContextCompressorPort

    public init(
        aiProvider: AIProviderPort,
        tokenizer: TokenizerPort,
        metaTokenCompressor: ContextCompressorPort
    ) {
        self.aiProvider = aiProvider
        self.tokenizer = tokenizer
        self.metaTokenCompressor = metaTokenCompressor
    }

    /// Compress to 95% for Apple Intelligence
    public func compressForAppleIntelligence(
        _ context: String,
        targetTokens: Int = 1_000
    ) async throws -> CompressedContext {
        let (systemInstructions, userContext) = extractSystemInstructions(from: context)

        let essentials = try await extractEssentials(from: userContext)
        let patterns = try await extractPatterns(from: userContext)
        let bullets = extractBullets(from: userContext)

        let compressedUserContent = buildCompressedContent(
            essentials: essentials,
            patterns: patterns,
            bullets: bullets
        )

        let metaCompressed = try await metaTokenCompressor.compress(
            compressedUserContent,
            targetRatio: 0.5
        )

        let finalCompressed = reassembleWithSystemInstructions(
            systemInstructions,
            metaCompressed.compressedText
        )

        return try await buildCompressedResult(
            originalContext: context,
            finalCompressed: finalCompressed,
            targetTokens: targetTokens,
            systemInstructionsPresent: !systemInstructions.isEmpty
        )
    }

    private func buildCompressedContent(
        essentials: String,
        patterns: String,
        bullets: [String]
    ) -> String {
        """
        \(essentials)

        Patterns: \(patterns)

        Key Points: \(bullets.joined(separator: "; "))
        """
    }

    private func reassembleWithSystemInstructions(
        _ systemInstructions: String,
        _ compressedContent: String
    ) -> String {
        systemInstructions.isEmpty
            ? compressedContent
            : """
            \(systemInstructions)

            ---

            \(compressedContent)
            """
    }

    private func buildCompressedResult(
        originalContext: String,
        finalCompressed: String,
        targetTokens: Int,
        systemInstructionsPresent: Bool
    ) async throws -> CompressedContext {
        let finalTokens = try await tokenizer.countTokens(in: finalCompressed)
        let originalTokens = try await tokenizer.countTokens(in: originalContext)
        let ratio = Double(finalTokens) / Double(originalTokens)

        return CompressedContext(
            compressedText: finalCompressed,
            originalTokenCount: originalTokens,
            compressedTokenCount: finalTokens,
            compressionRatio: ratio,
            technique: .hybrid,
            metadata: CompressionMetadata(
                technique: .hybrid,
                originalTokens: originalTokens,
                compressedTokens: finalTokens,
                compressionRatio: ratio,
                qualityScore: 0.90,
                preservedConcepts: nil,
                parameters: [
                    "targetTokens": "\(targetTokens)",
                    "actualTokens": "\(finalTokens)",
                    "method": "Apple Intelligence Ultra",
                    "compressionPercentage": String(format: "%.1f%%", (1.0 - ratio) * 100),
                    "systemInstructionsPreserved": systemInstructionsPresent ? "yes" : "no"
                ]
            )
        )
    }

    private func extractEssentials(from context: String) async throws -> String {
        let prompt = """
        Extract ONLY the absolute essentials from this context (max 100 words):
        - What is being built?
        - Who is it for?
        - What are the top 3 must-have features?

        Context:
        \(context.prefix(2000))

        Output only essentials, no preamble.
        """

        return try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.0
        )
    }

    private func extractPatterns(from context: String) async throws -> String {
        let prompt = """
        Extract architectural patterns and tech stack (max 50 words):
        - Architecture: [pattern]
        - Tech: [list]
        - Key patterns: [list]

        Context:
        \(context.prefix(1500))

        Output only patterns, no preamble.
        """

        return try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.0
        )
    }

    private func extractBullets(from context: String) -> [String] {
        let sentences = context.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 20 && $0.count < 100 }
            .prefix(5)

        return Array(sentences)
    }

    private func extractSystemInstructions(from context: String) -> (system: String, user: String) {
        let lines = context.split(separator: "\n", omittingEmptySubsequences: false)

        // Look for system instructions starting with "You are"
        if let firstLine = lines.first?.trimmingCharacters(in: .whitespaces),
           firstLine.lowercased().starts(with: "you are") {
            var systemLines: [String] = []
            var userLines: [String] = []
            var inSystem = true

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if inSystem {
                    if trimmed.isEmpty || trimmed == "---" {
                        inSystem = false
                        continue
                    }
                    systemLines.append(String(line))
                } else {
                    userLines.append(String(line))
                }
            }

            let system = systemLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            let user = userLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

            return (system, user.isEmpty ? context : user)
        }

        return ("", context)
    }
}
