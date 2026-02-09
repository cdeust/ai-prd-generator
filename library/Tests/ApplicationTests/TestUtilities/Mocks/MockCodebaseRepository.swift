import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Simplified mock codebase repository for testing PRD generation
/// Only implements methods needed for RAG context retrieval
public actor MockPRDCodebaseRepository: CodebaseRepositoryPort {
    private var files: [UUID: CodeFile] = [:]
    private var searchResults: [(file: CodeFile, similarity: Float)] = []
    private var shouldFail = false
    private var failureError: Error?

    public init() {}

    // MARK: - Configuration

    public func configure(
        searchResults: [(file: CodeFile, similarity: Float)],
        shouldFail: Bool = false,
        error: Error? = nil
    ) {
        self.searchResults = searchResults
        self.shouldFail = shouldFail
        self.failureError = error
    }

    public func reset() {
        files.removeAll()
        searchResults.removeAll()
        shouldFail = false
        failureError = nil
    }

    // MARK: - Used Methods (for PRD generation)

    public func searchFiles(
        in codebaseId: UUID,
        embedding: [Float],
        limit: Int,
        similarityThreshold: Float?
    ) async throws -> [(file: CodeFile, similarity: Float)] {
        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }

        var results = searchResults
        if let threshold = similarityThreshold {
            results = results.filter { $0.similarity >= threshold }
        }

        return Array(results.prefix(limit))
    }

    // MARK: - Stub implementations (not used in PRD generation)

    public func createCodebase(_ codebase: Codebase) async throws -> Codebase {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func getCodebase(by id: UUID) async throws -> Codebase? {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func listCodebases(forUser userId: UUID) async throws -> [Codebase] {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func updateCodebase(_ codebase: Codebase) async throws -> Codebase {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func deleteCodebase(_ id: UUID) async throws {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func saveProject(_ project: CodebaseProject) async throws -> CodebaseProject {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func findProjectById(_ id: UUID) async throws -> CodebaseProject? {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func findProjectByRepository(url: String, branch: String) async throws -> CodebaseProject? {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func updateProject(_ project: CodebaseProject) async throws -> CodebaseProject {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func deleteProject(_ id: UUID) async throws {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func updateProjectIndexingError(projectId: UUID, error: String) async throws {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func listProjects(limit: Int, offset: Int) async throws -> [CodebaseProject] {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func saveFiles(_ files: [CodeFile], projectId: UUID) async throws -> [CodeFile] {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func addFile(_ file: CodeFile) async throws -> CodeFile {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func findFilesByProject(_ projectId: UUID) async throws -> [CodeFile] {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func findFile(projectId: UUID, path: String) async throws -> CodeFile? {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func updateFileParsed(fileId: UUID, isParsed: Bool, error: String?) async throws {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func saveChunks(_ chunks: [CodeChunk], projectId: UUID) async throws -> [CodeChunk] {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func findChunksByProject(_ projectId: UUID, limit: Int, offset: Int) async throws -> [CodeChunk] {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func findChunksByFile(_ fileId: UUID) async throws -> [CodeChunk] {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func findChunksInFile(
        codebaseId: UUID,
        filePath: String,
        endLineBefore: Int?,
        startLineAfter: Int?,
        limit: Int
    ) async throws -> [CodeChunk] {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func deleteChunksByProject(_ projectId: UUID) async throws {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func saveEmbeddings(_ embeddings: [CodeEmbedding], projectId: UUID) async throws {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func findSimilarChunks(
        projectId: UUID,
        queryEmbedding: [Float],
        limit: Int,
        similarityThreshold: Float
    ) async throws -> [SimilarCodeChunk] {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func saveMerkleRoot(projectId: UUID, rootHash: String) async throws {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func getMerkleRoot(projectId: UUID) async throws -> String? {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func saveMerkleNodes(_ nodes: [MerkleNode], projectId: UUID) async throws {
        fatalError("Not implemented - not needed for PRD generation tests")
    }

    public func getMerkleNodes(projectId: UUID) async throws -> [MerkleNode] {
        fatalError("Not implemented - not needed for PRD generation tests")
    }
}
