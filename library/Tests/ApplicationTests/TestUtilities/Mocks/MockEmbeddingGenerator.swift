import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Mock embedding generator for testing
/// Generates deterministic embeddings based on text hash
public actor MockPRDEmbeddingGenerator: EmbeddingGeneratorPort {
    public let dimension: Int
    public let modelName: String
    public let embeddingVersion: Int

    private var shouldFail = false
    private var failureError: Error?
    private var fixedEmbedding: [Float]?

    public init(
        dimension: Int = 384,
        modelName: String = "mock-embedder",
        embeddingVersion: Int = 1
    ) {
        self.dimension = dimension
        self.modelName = modelName
        self.embeddingVersion = embeddingVersion
    }

    // MARK: - Configuration

    public func configure(
        fixedEmbedding: [Float]? = nil,
        shouldFail: Bool = false,
        error: Error? = nil
    ) {
        self.fixedEmbedding = fixedEmbedding
        self.shouldFail = shouldFail
        self.failureError = error
    }

    public func reset() {
        fixedEmbedding = nil
        shouldFail = false
        failureError = nil
    }

    // MARK: - EmbeddingGeneratorPort

    public func generateEmbedding(text: String) async throws -> [Float] {
        if shouldFail {
            throw failureError ?? MockEmbeddingError.configured
        }

        if let fixed = fixedEmbedding {
            return fixed
        }

        // Generate deterministic embedding based on text
        return generateDeterministicEmbedding(for: text)
    }

    public func generateEmbeddings(texts: [String]) async throws -> [[Float]] {
        if shouldFail {
            throw failureError ?? MockEmbeddingError.configured
        }

        return try await texts.asyncMap { text in
            try await self.generateEmbedding(text: text)
        }
    }

    public func generateCodeEmbedding(chunk: CodeChunk) async throws -> CodeEmbedding {
        if shouldFail {
            throw failureError ?? MockEmbeddingError.configured
        }

        let embedding = try await generateEmbedding(text: chunk.content)

        return CodeEmbedding(
            chunkId: chunk.id,
            projectId: chunk.fileId,
            embedding: embedding,
            model: modelName,
            embeddingVersion: embeddingVersion,
            createdAt: Date()
        )
    }

    // MARK: - Private Helpers

    private func generateDeterministicEmbedding(for text: String) -> [Float] {
        // Create deterministic but unique embeddings
        var hasher = Hasher()
        hasher.combine(text)
        let hash = hasher.finalize()

        var embedding = [Float](repeating: 0.0, count: dimension)

        // Use hash to seed pseudo-random embedding
        var seed = hash
        for i in 0..<dimension {
            // XOR-shift pseudo-random
            seed ^= seed << 13
            seed ^= seed >> 7
            seed ^= seed << 17

            // Normalize to [-1, 1]
            let value = Float(seed % 1000) / 500.0 - 1.0
            embedding[i] = value
        }

        // Normalize to unit vector
        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        return embedding.map { $0 / magnitude }
    }
}

// MARK: - Mock Error

public enum MockEmbeddingError: Error, Sendable {
    case configured
}

// MARK: - Async Helpers

private extension Array {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var results: [T] = []
        for element in self {
            try await results.append(transform(element))
        }
        return results
    }
}
