import AIPRDSharedUtilities
import AIPRDRAGEngine
import Foundation
import AIPRDSharedUtilities

/// Use case for indexing a codebase
/// Following SRP - ONE job: index codebase files
/// Following DIP - depends on ports only
public struct IndexCodebaseUseCase: Sendable {
    private let codebaseRepository: CodebaseRepositoryPort
    private let codeParser: CodeParserPort
    private let embeddingGenerator: EmbeddingGeneratorPort
    private let hashingService: HashingPort
    private let contextualEnricher: (any ChunkEnricherPort)?
    private let merkleTreeBuilder: MerkleTreeBuilder
    private let statusUpdater: IndexCodebaseStatusUpdater

    public init(
        codebaseRepository: CodebaseRepositoryPort,
        codeParser: CodeParserPort,
        embeddingGenerator: EmbeddingGeneratorPort,
        hashingService: HashingPort,
        contextualEnricher: (any ChunkEnricherPort)? = nil
    ) {
        self.codebaseRepository = codebaseRepository
        self.codeParser = codeParser
        self.embeddingGenerator = embeddingGenerator
        self.hashingService = hashingService
        self.contextualEnricher = contextualEnricher
        self.merkleTreeBuilder = MerkleTreeBuilder(hashingService: hashingService)
        self.statusUpdater = IndexCodebaseStatusUpdater(codebaseRepository: codebaseRepository)
    }

    public func execute(
        codebaseId: UUID,
        projectId: UUID,
        files: [(file: CodeFile, content: String)],
        progressHandler: ((Double) -> Void)? = nil
    ) async throws {
        let savedFiles = try await saveFilesToRepository(files: files, projectId: projectId)
        let filesWithContent = zip(savedFiles, files).map { (file: $0, content: $1.content) }

        let indexResult = try await processAndIndexFiles(
            files: filesWithContent,
            codebaseId: codebaseId,
            projectId: projectId,
            progressHandler: progressHandler
        )

        try await finalizeIndexing(
            codebaseId: codebaseId,
            projectId: projectId,
            fileCount: files.count,
            indexResult: indexResult,
            filesWithContent: filesWithContent
        )
    }

    private func saveFilesToRepository(
        files: [(file: CodeFile, content: String)],
        projectId: UUID
    ) async throws -> [CodeFile] {
        try await codebaseRepository.saveFiles(files.map { $0.file }, projectId: projectId)
    }

    private func processAndIndexFiles(
        files: [(file: CodeFile, content: String)],
        codebaseId: UUID,
        projectId: UUID,
        progressHandler: ((Double) -> Void)?
    ) async throws -> (chunks: [CodeChunk], embeddings: [CodeEmbedding]) {
        let (allChunks, allEmbeddings) = try await processFiles(
            files: files,
            codebaseId: codebaseId,
            projectId: projectId,
            progressHandler: progressHandler
        )
        try await saveIndexData(chunks: allChunks, embeddings: allEmbeddings, projectId: projectId)
        return (allChunks, allEmbeddings)
    }

    private func finalizeIndexing(
        codebaseId: UUID,
        projectId: UUID,
        fileCount: Int,
        indexResult: (chunks: [CodeChunk], embeddings: [CodeEmbedding]),
        filesWithContent: [(file: CodeFile, content: String)]
    ) async throws {
        let detectedLanguages = detectLanguagesFromFiles(filesWithContent)
        let detectedFrameworks = extractFrameworksFromChunks(indexResult.chunks)

        try await statusUpdater.updateProjectStatus(
            projectId: projectId,
            totalFiles: fileCount,
            totalChunks: indexResult.chunks.count,
            detectedLanguages: detectedLanguages,
            detectedFrameworks: detectedFrameworks
        )

        try await statusUpdater.updateCodebaseStatus(
            codebaseId: codebaseId,
            totalFiles: fileCount,
            detectedLanguages: detectedLanguages
        )
    }

    private func detectLanguagesFromFiles(
        _ files: [(file: CodeFile, content: String)]
    ) -> [String] {
        Array(Set(files.compactMap { $0.file.language?.rawValue })).sorted()
    }

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
                try await codebaseRepository.updateFileParsed(fileId: file.id, isParsed: true, error: nil)
            } catch {
                try? await codebaseRepository.updateFileParsed(
                    fileId: file.id,
                    isParsed: false,
                    error: error.localizedDescription
                )
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
        let (enrichedChunks, embeddings) = try await generateEmbeddings(for: chunks, projectId: projectId)
        return (enrichedChunks, embeddings)
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
    ) async throws -> (chunks: [CodeChunk], embeddings: [CodeEmbedding]) {
        let enrichedChunks: [CodeChunk]
        let contents: [String]

        if let enricher = contextualEnricher {
            print("✨ [IndexCodebase] Enriching \(chunks.count) chunks with contextual information...")
            let codebaseContext = try await statusUpdater.buildCodebaseContext(projectId: projectId)
            let enrichedResults = try await enricher.enrichChunks(chunks, codebaseContext: codebaseContext)

            enrichedChunks = zip(chunks, enrichedResults).map { original, enriched in
                createEnrichedChunk(from: original, enrichedContent: enriched.enrichedContent)
            }
            contents = enrichedResults.map { $0.enrichedContent }
            print("✅ [IndexCodebase] Contextual enrichment complete (+49% expected precision boost)")
        } else {
            enrichedChunks = chunks
            contents = chunks.map { $0.content }
        }

        let embeddings = try await embeddingGenerator.generateEmbeddings(texts: contents)

        let codeEmbeddings = enrichedChunks.enumerated().map { index, chunk in
            CodeEmbedding(
                chunkId: chunk.id,
                projectId: projectId,
                embedding: embeddings[index],
                model: embeddingGenerator.modelName,
                embeddingVersion: embeddingGenerator.embeddingVersion
            )
        }

        return (enrichedChunks, codeEmbeddings)
    }

    private func createEnrichedChunk(from original: CodeChunk, enrichedContent: String) -> CodeChunk {
        CodeChunk(
            id: original.id,
            fileId: original.fileId,
            codebaseId: original.codebaseId,
            projectId: original.projectId,
            filePath: original.filePath,
            content: original.content,
            enrichedContent: enrichedContent,
            contentHash: original.contentHash,
            startLine: original.startLine,
            endLine: original.endLine,
            chunkType: original.chunkType,
            language: original.language,
            symbols: original.symbols,
            imports: original.imports,
            tokenCount: original.tokenCount,
            createdAt: original.createdAt
        )
    }

    private func saveIndexData(
        chunks: [CodeChunk],
        embeddings: [CodeEmbedding],
        projectId: UUID
    ) async throws {
        let savedChunks = try await codebaseRepository.saveChunks(chunks, projectId: projectId)
        try await codebaseRepository.saveEmbeddings(embeddings, projectId: projectId)

        let merkleTree = merkleTreeBuilder.buildMerkleTree(from: savedChunks)
        if let rootNode = merkleTree.rootNode {
            let flatNodes = merkleTreeBuilder.flattenMerkleTree(rootNode, projectId: projectId)
            try await codebaseRepository.saveMerkleNodes(flatNodes, projectId: projectId)
            try await codebaseRepository.saveMerkleRoot(projectId: projectId, rootHash: merkleTree.rootHash)
        }
    }

    private func extractFrameworksFromChunks(_ chunks: [CodeChunk]) -> [String] {
        let imports = chunks.map { $0.imports }.joined()
            .compactMap { $0.split(separator: ".").first.map(String.init) }
        return Array(Set(imports)).sorted()
    }
}
