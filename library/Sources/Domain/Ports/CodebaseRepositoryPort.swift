import Foundation

/// Port for codebase persistence and retrieval
/// Domain defines the interface, Infrastructure implements it
/// Following Interface Segregation Principle
public protocol CodebaseRepositoryPort: Sendable {
    // MARK: - Codebase Operations

    /// Create a new codebase
    func createCodebase(_ codebase: Codebase) async throws -> Codebase

    /// Get codebase by ID
    func getCodebase(by id: UUID) async throws -> Codebase?

    /// List codebases for a user
    func listCodebases(forUser userId: UUID) async throws -> [Codebase]

    /// Update codebase
    func updateCodebase(_ codebase: Codebase) async throws -> Codebase

    /// Delete codebase
    func deleteCodebase(_ id: UUID) async throws

    // MARK: - Codebase Project Operations

    /// Save codebase project with indexing metadata
    func saveProject(_ project: CodebaseProject) async throws -> CodebaseProject

    /// Find project by ID
    func findProjectById(_ id: UUID) async throws -> CodebaseProject?

    /// Find project by repository URL and branch
    func findProjectByRepository(url: String, branch: String) async throws -> CodebaseProject?

    /// Update project
    func updateProject(_ project: CodebaseProject) async throws -> CodebaseProject

    /// Delete project
    func deleteProject(_ id: UUID) async throws

    /// Update project indexing error status
    func updateProjectIndexingError(projectId: UUID, error: String) async throws

    /// List projects with pagination
    func listProjects(limit: Int, offset: Int) async throws -> [CodebaseProject]

    // MARK: - Code File Operations

    /// Save multiple files
    func saveFiles(_ files: [CodeFile], projectId: UUID) async throws -> [CodeFile]

    /// Add single file
    func addFile(_ file: CodeFile) async throws -> CodeFile

    /// Find files by project ID
    func findFilesByProject(_ projectId: UUID) async throws -> [CodeFile]

    /// Find specific file by path
    func findFile(projectId: UUID, path: String) async throws -> CodeFile?

    /// Update file parsed status
    func updateFileParsed(fileId: UUID, isParsed: Bool, error: String?) async throws

    // MARK: - Code Chunk Operations (RAG)

    /// Save code chunks
    func saveChunks(_ chunks: [CodeChunk], projectId: UUID) async throws -> [CodeChunk]

    /// Find chunks by project
    func findChunksByProject(_ projectId: UUID, limit: Int, offset: Int) async throws -> [CodeChunk]

    /// Find chunks by file
    func findChunksByFile(_ fileId: UUID) async throws -> [CodeChunk]

    /// Find chunks in file by line range (for contextual retrieval)
    func findChunksInFile(
        codebaseId: UUID,
        filePath: String,
        endLineBefore: Int?,
        startLineAfter: Int?,
        limit: Int
    ) async throws -> [CodeChunk]

    /// Delete chunks for project (for re-indexing)
    func deleteChunksByProject(_ projectId: UUID) async throws

    // MARK: - Embedding Operations (Vector Search)

    /// Save embeddings for chunks
    func saveEmbeddings(_ embeddings: [CodeEmbedding], projectId: UUID) async throws

    /// Find similar chunks using vector search (RAG core functionality)
    func findSimilarChunks(
        projectId: UUID,
        queryEmbedding: [Float],
        limit: Int,
        similarityThreshold: Float
    ) async throws -> [SimilarCodeChunk]

    /// Search files by semantic similarity
    func searchFiles(
        in codebaseId: UUID,
        embedding: [Float],
        limit: Int,
        similarityThreshold: Float?
    ) async throws -> [(file: CodeFile, similarity: Float)]

    // MARK: - Merkle Tree Operations (Code Integrity)

    /// Save Merkle root hash
    func saveMerkleRoot(projectId: UUID, rootHash: String) async throws

    /// Get Merkle root hash
    func getMerkleRoot(projectId: UUID) async throws -> String?

    /// Save Merkle tree nodes
    func saveMerkleNodes(_ nodes: [MerkleNode], projectId: UUID) async throws

    /// Get Merkle tree nodes
    func getMerkleNodes(projectId: UUID) async throws -> [MerkleNode]
}
