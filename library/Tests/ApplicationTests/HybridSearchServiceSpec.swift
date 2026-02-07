import AIPRDOrchestrationEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import XCTest
@testable import Application
@testable import Domain

/// Real tests for HybridSearchService implementation
/// Tests the ACTUAL RRF fusion algorithm, not mock logic
final class HybridSearchServiceSpec: XCTestCase {

    // MARK: - Test: RRF Formula Correctness

    func testRRF_formula_correctness() async throws {
        // Given: Mock ports with controlled rankings
        let embedding = [Float](repeating: 1.0, count: 10)
        let projectId = UUID()

        // Create test chunks with known IDs
        let chunk1 = createTestChunk(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        let chunk2 = createTestChunk(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)
        let chunk3 = createTestChunk(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!)

        // Vector results: chunk1 rank 0, chunk2 rank 1
        let vectorResults = [
            SimilarCodeChunk(chunk: chunk1, similarity: 0.9),
            SimilarCodeChunk(chunk: chunk2, similarity: 0.8)
        ]

        // Keyword results: chunk2 rank 0, chunk3 rank 1
        let keywordResults = [
            FullTextSearchResult(chunk: chunk2, bm25Score: 10.0, rank: 0),
            FullTextSearchResult(chunk: chunk3, bm25Score: 5.0, rank: 1)
        ]

        let mockRepo = MockCodebaseRepository(vectorResults: vectorResults)
        let mockEmbedding = MockEmbeddingGenerator(embedding: embedding)
        let mockFullText = MockFullTextSearch(results: keywordResults)

        // When: Call ACTUAL service
        let service = HybridSearchService(
            codebaseRepository: mockRepo,
            embeddingGenerator: mockEmbedding,
            fullTextSearch: mockFullText
        )

        let results = try await service.search(
            query: "test",
            projectId: projectId,
            limit: 10,
            alpha: 0.7  // 70% vector, 30% keyword
        )

        // Then: Validate RRF math
        // chunk1: vectorRRF = 1/(0+60) = 0.01667, keywordRRF = 0.0
        // finalScore = 0.01667 * 0.7 + 0.0 * 0.3 = 0.01167

        // chunk2: vectorRRF = 1/(1+60) = 0.01639, keywordRRF = 1/(0+60) = 0.01667
        // finalScore = 0.01639 * 0.7 + 0.01667 * 0.3 = 0.01647

        // chunk3: vectorRRF = 0.0, keywordRRF = 1/(1+60) = 0.01639
        // finalScore = 0.0 * 0.7 + 0.01639 * 0.3 = 0.00492

        // Expected ranking: chunk2 (0.01647) > chunk1 (0.01167) > chunk3 (0.00492)

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].chunk.id, chunk2.id, "chunk2 should rank first")
        XCTAssertEqual(results[1].chunk.id, chunk1.id, "chunk1 should rank second")
        XCTAssertEqual(results[2].chunk.id, chunk3.id, "chunk3 should rank third")

        // Validate actual scores match RRF formula
        XCTAssertEqual(results[0].hybridScore, 0.01647, accuracy: 0.0001)
        XCTAssertEqual(results[1].hybridScore, 0.01167, accuracy: 0.0001)
        XCTAssertEqual(results[2].hybridScore, 0.00492, accuracy: 0.0001)
    }

    // MARK: - Test: Alpha Parameter (Pure Vector)

    func testAlpha_1_0_uses_only_vector_ranking() async throws {
        let projectId = UUID()
        let embedding = [Float](repeating: 1.0, count: 10)

        let chunk1 = createTestChunk(id: UUID())
        let chunk2 = createTestChunk(id: UUID())

        // Vector: chunk1 > chunk2
        let vectorResults = [
            SimilarCodeChunk(chunk: chunk1, similarity: 0.9),
            SimilarCodeChunk(chunk: chunk2, similarity: 0.7)
        ]

        // Keyword: chunk2 > chunk1 (opposite ranking)
        let keywordResults = [
            FullTextSearchResult(chunk: chunk2, bm25Score: 10.0, rank: 0),
            FullTextSearchResult(chunk: chunk1, bm25Score: 5.0, rank: 1)
        ]

        let service = HybridSearchService(
            codebaseRepository: MockCodebaseRepository(vectorResults: vectorResults),
            embeddingGenerator: MockEmbeddingGenerator(embedding: embedding),
            fullTextSearch: MockFullTextSearch(results: keywordResults)
        )

        // alpha=1.0 means 100% vector, 0% keyword
        let results = try await service.search(
            query: "test",
            projectId: projectId,
            alpha: 1.0
        )

        // Should follow vector ranking (chunk1 > chunk2)
        XCTAssertEqual(results[0].chunk.id, chunk1.id)
        XCTAssertEqual(results[1].chunk.id, chunk2.id)
    }

    // MARK: - Test: Alpha Parameter (Pure Keyword)

    func testAlpha_0_0_uses_only_keyword_ranking() async throws {
        let projectId = UUID()
        let embedding = [Float](repeating: 1.0, count: 10)

        let chunk1 = createTestChunk(id: UUID())
        let chunk2 = createTestChunk(id: UUID())

        // Vector: chunk1 > chunk2
        let vectorResults = [
            SimilarCodeChunk(chunk: chunk1, similarity: 0.9),
            SimilarCodeChunk(chunk: chunk2, similarity: 0.7)
        ]

        // Keyword: chunk2 > chunk1 (opposite ranking)
        let keywordResults = [
            FullTextSearchResult(chunk: chunk2, bm25Score: 10.0, rank: 0),
            FullTextSearchResult(chunk: chunk1, bm25Score: 5.0, rank: 1)
        ]

        let service = HybridSearchService(
            codebaseRepository: MockCodebaseRepository(vectorResults: vectorResults),
            embeddingGenerator: MockEmbeddingGenerator(embedding: embedding),
            fullTextSearch: MockFullTextSearch(results: keywordResults)
        )

        // alpha=0.0 means 0% vector, 100% keyword
        let results = try await service.search(
            query: "test",
            projectId: projectId,
            alpha: 0.0
        )

        // Should follow keyword ranking (chunk2 > chunk1)
        XCTAssertEqual(results[0].chunk.id, chunk2.id)
        XCTAssertEqual(results[1].chunk.id, chunk1.id)
    }

    // MARK: - Helpers

    private func createTestChunk(id: UUID) -> CodeChunk {
        CodeChunk(
            id: id,
            fileId: UUID(),
            codebaseId: UUID(),
            projectId: UUID(),
            filePath: "test.swift",
            content: "test content",
            contentHash: "hash",
            startLine: 1,
            endLine: 10,
            chunkType: .function,
            language: .swift,
            tokenCount: 50
        )
    }
}

// MARK: - Mock Ports

private final class MockCodebaseRepository: CodebaseRepositoryPort {
    private let vectorResults: [SimilarCodeChunk]

    init(vectorResults: [SimilarCodeChunk]) {
        self.vectorResults = vectorResults
    }

    func findSimilarChunks(
        projectId: UUID,
        queryEmbedding: [Float],
        limit: Int,
        similarityThreshold: Float
    ) async throws -> [SimilarCodeChunk] {
        return vectorResults
    }

    // Minimal stubs for unused methods
    func createCodebase(_ codebase: Codebase) async throws -> Codebase { fatalError() }
    func getCodebase(by id: UUID) async throws -> Codebase? { fatalError() }
    func listCodebases(forUser userId: UUID) async throws -> [Codebase] { fatalError() }
    func updateCodebase(_ codebase: Codebase) async throws -> Codebase { fatalError() }
    func deleteCodebase(_ id: UUID) async throws { fatalError() }
    func saveProject(_ project: CodebaseProject) async throws -> CodebaseProject { fatalError() }
    func findProjectById(_ id: UUID) async throws -> CodebaseProject? { fatalError() }
    func findProjectByRepository(url: String, branch: String) async throws -> CodebaseProject? { fatalError() }
    func updateProject(_ project: CodebaseProject) async throws -> CodebaseProject { fatalError() }
    func deleteProject(_ id: UUID) async throws { fatalError() }
    func updateProjectIndexingError(projectId: UUID, error: String) async throws { fatalError() }
    func listProjects(limit: Int, offset: Int) async throws -> [CodebaseProject] { fatalError() }
    func saveFiles(_ files: [CodeFile], projectId: UUID) async throws -> [CodeFile] { fatalError() }
    func addFile(_ file: CodeFile) async throws -> CodeFile { fatalError() }
    func findFilesByProject(_ projectId: UUID) async throws -> [CodeFile] { fatalError() }
    func findFile(projectId: UUID, path: String) async throws -> CodeFile? { fatalError() }
    func updateFileParsed(fileId: UUID, isParsed: Bool, error: String?) async throws { fatalError() }
    func saveChunks(_ chunks: [CodeChunk], projectId: UUID) async throws -> [CodeChunk] { fatalError() }
    func findChunksByProject(_ projectId: UUID, limit: Int, offset: Int) async throws -> [CodeChunk] { fatalError() }
    func findChunksByFile(_ fileId: UUID) async throws -> [CodeChunk] { fatalError() }
    func findChunksInFile(codebaseId: UUID, filePath: String, endLineBefore: Int?, startLineAfter: Int?, limit: Int) async throws -> [CodeChunk] { fatalError() }
    func deleteChunksByProject(_ projectId: UUID) async throws { fatalError() }
    func saveEmbeddings(_ embeddings: [CodeEmbedding], projectId: UUID) async throws { fatalError() }
    func searchFiles(in codebaseId: UUID, embedding: [Float], limit: Int, similarityThreshold: Float?) async throws -> [(file: CodeFile, similarity: Float)] { fatalError() }
    func saveMerkleRoot(projectId: UUID, rootHash: String) async throws { fatalError() }
    func getMerkleRoot(projectId: UUID) async throws -> String? { fatalError() }
    func saveMerkleNodes(_ nodes: [MerkleNode], projectId: UUID) async throws { fatalError() }
    func getMerkleNodes(projectId: UUID) async throws -> [MerkleNode] { fatalError() }
}

private final class MockEmbeddingGenerator: EmbeddingGeneratorPort {
    private let embedding: [Float]

    init(embedding: [Float]) {
        self.embedding = embedding
    }

    func generateEmbedding(text: String) async throws -> [Float] {
        return embedding
    }

    func generateEmbeddings(texts: [String]) async throws -> [[Float]] {
        return texts.map { _ in embedding }
    }

    func generateCodeEmbedding(chunk: CodeChunk) async throws -> CodeEmbedding {
        fatalError()
    }

    var dimension: Int { embedding.count }
    var modelName: String { "test" }
    var embeddingVersion: Int { 1 }
}

private final class MockFullTextSearch: FullTextSearchPort {
    private let results: [FullTextSearchResult]

    init(results: [FullTextSearchResult]) {
        self.results = results
    }

    func searchChunks(
        in codebaseId: UUID,
        query: String,
        limit: Int,
        minScore: Float
    ) async throws -> [FullTextSearchResult] {
        return results
    }

    func searchFiles(in codebaseId: UUID, query: String, limit: Int) async throws -> [(file: CodeFile, bm25Score: Float)] {
        fatalError()
    }
}
