import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

/// Natural Language Embeddings Implementation
/// Implements EmbeddingGeneratorPort using Apple's NaturalLanguage framework
/// Following Single Responsibility: Only handles embedding generation via NL framework
///
/// IMPORTANT: This uses NaturalLanguage framework (iOS 16+), NOT Apple Intelligence
/// - NLEmbedding.sentenceEmbedding provides basic word/sentence embeddings
/// - This is NOT the same as Foundation Models (iOS 26+)
/// - Suitable for basic similarity comparisons and search
/// - For advanced embeddings, use OpenAI/Anthropic providers
@available(iOS 16.0, macOS 13.0, *)
public final class NaturalLanguageEmbeddings: EmbeddingGeneratorPort, Sendable {
    // MARK: - Properties

    private let embeddingDimension: Int
    private let modelIdentifier: String

    // MARK: - Initialization

    public init(
        embeddingDimension: Int = 1536,
        modelIdentifier: String = "natural-language-default"
    ) {
        self.embeddingDimension = embeddingDimension
        self.modelIdentifier = modelIdentifier
    }

    // MARK: - EmbeddingGeneratorPort Implementation

    public func generateEmbedding(text: String) async throws -> [Float] {
        let embeddings = try await generateEmbeddings(texts: [text])
        guard let embedding = embeddings.first else {
            throw EmbeddingError.generationFailed
        }
        return embedding
    }

    public func generateEmbeddings(
        texts: [String]
    ) async throws -> [[Float]] {
        guard !texts.isEmpty else {
            return []
        }

        // Check if NaturalLanguage framework is available
        guard isNaturalLanguageAvailable() else {
            throw EmbeddingError.modelNotAvailable
        }

        // Process embeddings
        var embeddings: [[Float]] = []

        for text in texts {
            let embedding = try await generateSingleEmbedding(text)
            embeddings.append(embedding)
        }

        return embeddings
    }

    public func generateCodeEmbedding(chunk: CodeChunk) async throws -> CodeEmbedding {
        let embedding = try await generateEmbedding(text: chunk.content)
        return CodeEmbedding(
            id: UUID(),
            chunkId: chunk.id,
            projectId: chunk.projectId,
            embedding: embedding,
            model: modelName,
            embeddingVersion: embeddingVersion
        )
    }

    public var dimension: Int { embeddingDimension }
    public var modelName: String { modelIdentifier }
    public var embeddingVersion: Int { 1 }

    // MARK: - Private Methods

    private func isNaturalLanguageAvailable() -> Bool {
        #if canImport(NaturalLanguage)
        return true
        #else
        return false
        #endif
    }

    private func generateSingleEmbedding(
        _ text: String
    ) async throws -> [Float] {
        #if canImport(NaturalLanguage)
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let embedding = try self.generateUsingNaturalLanguage(text)
                    continuation.resume(returning: embedding)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        #else
        throw EmbeddingError.modelNotAvailable
        #endif
    }

    #if canImport(NaturalLanguage)
    private func generateUsingNaturalLanguage(_ text: String) throws -> [Float] {
        // Use NaturalLanguage framework for basic embeddings
        let embedding = NLEmbedding.sentenceEmbedding(for: .english)

        guard let vector = embedding?.vector(for: text) else {
            throw EmbeddingError.generationFailed
        }

        // NLEmbedding returns Double array, convert to Float
        let floatVector = vector.map { Float($0) }

        // Normalize to desired dimension
        return normalizeEmbedding(floatVector, targetDimension: embeddingDimension)
    }
    #endif

    private func normalizeEmbedding(
        _ embedding: [Float],
        targetDimension: Int
    ) -> [Float] {
        var result = embedding

        // Pad with zeros if too short
        while result.count < targetDimension {
            result.append(0.0)
        }

        // Truncate if too long
        if result.count > targetDimension {
            result = Array(result.prefix(targetDimension))
        }

        // Normalize to unit length
        let magnitude = sqrt(result.reduce(0) { $0 + $1 * $1 })
        if magnitude > 0 {
            result = result.map { $0 / magnitude }
        }

        return result
    }
}
