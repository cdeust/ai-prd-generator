import Foundation
import Domain

/// Use case for indexing a codebase
/// Following SRP - ONE job: index codebase files
/// Following DIP - depends on ports only
public struct IndexCodebaseUseCase: Sendable {
    // Dependencies: PORTS (interfaces)
    private let codebaseRepository: CodebaseRepositoryPort
    private let codeParser: CodeParserPort
    private let embeddingGenerator: EmbeddingGeneratorPort
    private let hashingService: HashingPort

    public init(
        codebaseRepository: CodebaseRepositoryPort,
        codeParser: CodeParserPort,
        embeddingGenerator: EmbeddingGeneratorPort,
        hashingService: HashingPort
    ) {
        self.codebaseRepository = codebaseRepository
        self.codeParser = codeParser
        self.embeddingGenerator = embeddingGenerator
        self.hashingService = hashingService
    }

    /// Execute indexing
    /// - Parameters:
    ///   - codebaseId: Parent codebase ID
    ///   - projectId: Codebase project to index
    ///   - files: Files to index with content
    ///   - progressHandler: Optional progress callback
    public func execute(
        codebaseId: UUID,
        projectId: UUID,
        files: [(file: CodeFile, content: String)],
        progressHandler: ((Double) -> Void)? = nil
    ) async throws {
        // Save files first (required for foreign key constraints on chunks)
        let savedFiles = try await codebaseRepository.saveFiles(
            files.map { $0.file },
            projectId: projectId
        )

        // Map original files to saved files (preserves order, uses DB-assigned IDs)
        let filesWithContent = zip(savedFiles, files).map { saved, original in
            (file: saved, content: original.content)
        }

        let (allChunks, allEmbeddings) = try await processFiles(
            files: filesWithContent,
            codebaseId: codebaseId,
            projectId: projectId,
            progressHandler: progressHandler
        )

        try await saveIndexData(
            chunks: allChunks,
            embeddings: allEmbeddings,
            projectId: projectId
        )

        // Detect languages from files and frameworks from parsed chunks
        let detectedLanguages = detectLanguagesFromFiles(filesWithContent)
        let detectedFrameworks = extractFrameworksFromChunks(allChunks)

        try await updateProjectStatus(
            projectId: projectId,
            totalFiles: files.count,
            totalChunks: allChunks.count,
            detectedLanguages: detectedLanguages,
            detectedFrameworks: detectedFrameworks
        )

        // Also update parent codebase status
        try await updateCodebaseStatus(
            codebaseId: codebaseId,
            totalFiles: files.count,
            detectedLanguages: detectedLanguages
        )
    }

    // MARK: - Private Methods

    private func processFiles(
        files: [(file: CodeFile, content: String)],
        codebaseId: UUID,
        projectId: UUID,
        progressHandler: ((Double) -> Void)?
    ) async throws -> (chunks: [CodeChunk], embeddings: [CodeEmbedding]) {
        var allChunks: [CodeChunk] = []
        var allEmbeddings: [CodeEmbedding] = []
        let totalFiles = files.count

        for (index, (file, content)) in files.enumerated() {
            do {
                let (chunks, embeddings) = try await processFile(
                    file: file,
                    content: content,
                    codebaseId: codebaseId,
                    projectId: projectId
                )

                allChunks.append(contentsOf: chunks)
                allEmbeddings.append(contentsOf: embeddings)

                // Mark file as successfully parsed
                try await codebaseRepository.updateFileParsed(fileId: file.id, isParsed: true, error: nil)
            } catch {
                // Mark file as failed with error message
                try? await codebaseRepository.updateFileParsed(fileId: file.id, isParsed: false, error: error.localizedDescription)
            }

            let progress = Double(index + 1) / Double(totalFiles)
            progressHandler?(progress)
        }

        return (allChunks, allEmbeddings)
    }

    private func processFile(
        file: CodeFile,
        content: String,
        codebaseId: UUID,
        projectId: UUID
    ) async throws -> (chunks: [CodeChunk], embeddings: [CodeEmbedding]) {
        let parsedChunks = try await codeParser.parseCode(content, filePath: file.filePath)
        let chunks = createCodeChunks(from: parsedChunks, file: file, codebaseId: codebaseId, projectId: projectId)
        let embeddings = try await generateEmbeddings(for: chunks, projectId: projectId)
        return (chunks, embeddings)
    }

    private func createCodeChunks(
        from parsedChunks: [ParsedCodeChunk],
        file: CodeFile,
        codebaseId: UUID,
        projectId: UUID
    ) -> [CodeChunk] {
        parsedChunks.map { parsed in
            CodeChunk(
                fileId: file.id,
                codebaseId: codebaseId,
                projectId: projectId,
                filePath: file.filePath,
                content: parsed.content,
                contentHash: hashingService.sha256(of: parsed.content),
                startLine: parsed.startLine,
                endLine: parsed.endLine,
                chunkType: parsed.type,
                language: file.language ?? .swift,
                symbols: parsed.symbols,
                imports: parsed.imports,
                tokenCount: parsed.tokenCount
            )
        }
    }

    private func generateEmbeddings(
        for chunks: [CodeChunk],
        projectId: UUID
    ) async throws -> [CodeEmbedding] {
        let contents = chunks.map { $0.content }
        let embeddings = try await embeddingGenerator.generateEmbeddings(texts: contents)

        return chunks.enumerated().map { index, chunk in
            CodeEmbedding(
                chunkId: chunk.id,
                projectId: projectId,
                embedding: embeddings[index],
                model: embeddingGenerator.modelName,
                embeddingVersion: embeddingGenerator.embeddingVersion
            )
        }
    }

    private func saveIndexData(
        chunks: [CodeChunk],
        embeddings: [CodeEmbedding],
        projectId: UUID
    ) async throws {
        let savedChunks = try await codebaseRepository.saveChunks(chunks, projectId: projectId)
        try await codebaseRepository.saveEmbeddings(embeddings, projectId: projectId)

        let merkleTree = buildMerkleTree(from: savedChunks)
        if let rootNode = merkleTree.rootNode {
            let flatNodes = flattenMerkleTree(rootNode, projectId: projectId)
            try await codebaseRepository.saveMerkleNodes(flatNodes, projectId: projectId)
            try await codebaseRepository.saveMerkleRoot(projectId: projectId, rootHash: merkleTree.rootHash)
        }
    }

    private func buildMerkleTree(from chunks: [CodeChunk]) -> MerkleTree {
        guard !chunks.isEmpty else {
            return MerkleTree(rootHash: "", rootNode: nil, totalFiles: 0)
        }

        var nodes: [MerkleNode] = chunks.map { chunk in
            .leaf(id: UUID(), hash: chunk.contentHash, filePath: chunk.filePath)
        }

        while nodes.count > 1 {
            var nextLevel: [MerkleNode] = []
            for i in stride(from: 0, to: nodes.count, by: 2) {
                if i + 1 < nodes.count {
                    let combinedHash = hashingService.sha256(of: nodes[i].hash + nodes[i + 1].hash)
                    let parent = MerkleNode.branch(id: UUID(), hash: combinedHash, left: nodes[i], right: nodes[i + 1])
                    nextLevel.append(parent)
                } else {
                    nextLevel.append(nodes[i])
                }
            }
            nodes = nextLevel
        }

        return MerkleTree(rootHash: nodes.first?.hash ?? "", rootNode: nodes.first, totalFiles: chunks.count)
    }

    private func flattenMerkleTree(_ node: MerkleNode, projectId: UUID, level: Int = 0, position: Int = 0) -> [MerkleNode] {
        var result: [MerkleNode] = [node]
        if case .branch(_, _, let left, let right) = node {
            result.append(contentsOf: flattenMerkleTree(left, projectId: projectId, level: level + 1, position: position * 2))
            result.append(contentsOf: flattenMerkleTree(right, projectId: projectId, level: level + 1, position: position * 2 + 1))
        }
        return result
    }

    private func updateProjectStatus(
        projectId: UUID,
        totalFiles: Int,
        totalChunks: Int,
        detectedLanguages: [String],
        detectedFrameworks: [String]
    ) async throws {
        guard let project = try await codebaseRepository.findProjectById(projectId) else { return }

        let updatedProject = CodebaseProject(
            id: project.id,
            codebaseId: project.codebaseId,
            name: project.name,
            repositoryUrl: project.repositoryUrl,
            branch: project.branch,
            commitSha: project.commitSha,
            indexingStatus: .completed,
            indexingStartedAt: project.indexingStartedAt,
            indexingCompletedAt: Date(),
            indexingError: nil,
            totalFiles: totalFiles,
            totalChunks: totalChunks,
            totalTokens: project.totalTokens,
            merkleRootHash: project.merkleRootHash,
            detectedLanguages: detectedLanguages,
            detectedFrameworks: detectedFrameworks,
            architecturePatterns: project.architecturePatterns,
            createdAt: project.createdAt,
            updatedAt: Date()
        )
        _ = try await codebaseRepository.updateProject(updatedProject)
    }

    private func updateCodebaseStatus(
        codebaseId: UUID,
        totalFiles: Int,
        detectedLanguages: [String]
    ) async throws {
        guard let codebase = try await codebaseRepository.getCodebase(by: codebaseId) else { return }

        let updatedCodebase = Codebase(
            id: codebase.id,
            userId: codebase.userId,
            name: codebase.name,
            repositoryUrl: codebase.repositoryUrl,
            localPath: codebase.localPath,
            indexingStatus: .completed,
            totalFiles: totalFiles,
            indexedFiles: totalFiles,
            detectedLanguages: detectedLanguages,
            createdAt: codebase.createdAt,
            lastIndexedAt: Date()
        )
        _ = try await codebaseRepository.updateCodebase(updatedCodebase)
    }

    private func detectLanguagesFromFiles(_ files: [(file: CodeFile, content: String)]) -> [String] {
        Array(Set(files.compactMap { $0.file.language?.rawValue })).sorted()
    }

    private func extractFrameworksFromChunks(_ chunks: [CodeChunk]) -> [String] {
        let imports = chunks.map { $0.imports }.joined()
            .compactMap { $0.split(separator: ".").first.map(String.init) }
        return Array(Set(imports)).sorted()
    }
}
