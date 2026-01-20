import Foundation
import Domain

/// Mapper for Codebase domain entities to/from Supabase records
/// Single Responsibility: Data transformation between Domain and Infrastructure
public struct SupabaseCodebaseMapper: Sendable {
    public init() {}
    // MARK: - Codebase Mapping

    public func codebaseToDomain(_ record: SupabaseCodebaseRecord) -> Codebase {
        Codebase(
            id: UUID(uuidString: record.id) ?? UUID(),
            userId: UUID(uuidString: record.userId) ?? UUID(),
            name: record.name,
            repositoryUrl: record.repositoryUrl,
            localPath: record.localPath,
            indexingStatus: IndexingStatus(rawValue: record.indexingStatus) ?? .pending,
            totalFiles: record.totalFiles,
            indexedFiles: record.indexedFiles,
            detectedLanguages: record.detectedLanguages,
            createdAt: parseISO8601Date(record.createdAt) ?? Date(),
            lastIndexedAt: record.lastIndexedAt.flatMap { parseISO8601Date($0) }
        )
    }

    func codebaseToRecord(_ domain: Codebase) -> SupabaseCodebaseRecord {
        SupabaseCodebaseRecord(
            id: domain.id.uuidString,
            userId: domain.userId.uuidString,
            name: domain.name,
            repositoryUrl: domain.repositoryUrl,
            localPath: domain.localPath,
            indexingStatus: domain.indexingStatus.rawValue,
            totalFiles: domain.totalFiles,
            indexedFiles: domain.indexedFiles,
            detectedLanguages: domain.detectedLanguages,
            lastIndexedAt: domain.lastIndexedAt.map { formatISO8601Date($0) },
            createdAt: formatISO8601Date(domain.createdAt),
            updatedAt: formatISO8601Date(Date())
        )
    }

    // MARK: - Date Helpers

    private func parseISO8601Date(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    private func formatISO8601Date(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    // MARK: - CodebaseProject Mapping

    public func projectToDomain(_ record: SupabaseCodebaseProjectRecord) -> CodebaseProject {
        CodebaseProject(
            id: UUID(uuidString: record.id) ?? UUID(),
            codebaseId: UUID(uuidString: record.codebaseId) ?? UUID(),
            name: record.name,
            repositoryUrl: record.repositoryUrl,
            branch: record.branch,
            commitSha: record.commitSha,
            indexingStatus: IndexingStatus(rawValue: record.indexingStatus) ?? .pending,
            indexingStartedAt: record.indexingStartedAt.flatMap { parseISO8601Date($0) },
            indexingCompletedAt: record.indexingCompletedAt.flatMap { parseISO8601Date($0) },
            indexingError: record.indexingError,
            totalFiles: record.totalFiles,
            totalChunks: record.totalChunks,
            totalTokens: record.totalTokens,
            merkleRootHash: record.merkleRootHash,
            detectedLanguages: record.detectedLanguages ?? [],
            detectedFrameworks: record.detectedFrameworks ?? [],
            architecturePatterns: mapArchitecturePatterns(record.architecturePatterns ?? []),
            createdAt: parseISO8601Date(record.createdAt) ?? Date(),
            updatedAt: parseISO8601Date(record.updatedAt) ?? Date()
        )
    }

    func projectToRecord(_ domain: CodebaseProject) -> SupabaseCodebaseProjectRecord {
        SupabaseCodebaseProjectRecord(
            id: domain.id.uuidString,
            codebaseId: domain.codebaseId.uuidString,
            name: domain.name,
            repositoryUrl: domain.repositoryUrl,
            branch: domain.branch,
            commitSha: domain.commitSha,
            indexingStatus: domain.indexingStatus.rawValue,
            indexingStartedAt: domain.indexingStartedAt.map { formatISO8601Date($0) },
            indexingCompletedAt: domain.indexingCompletedAt.map { formatISO8601Date($0) },
            indexingError: domain.indexingError,
            totalFiles: domain.totalFiles,
            totalChunks: domain.totalChunks,
            totalTokens: domain.totalTokens,
            merkleRootHash: domain.merkleRootHash,
            detectedLanguages: domain.detectedLanguages,
            detectedFrameworks: domain.detectedFrameworks,
            architecturePatterns: mapArchitecturePatternsToData(domain.architecturePatterns),
            createdAt: formatISO8601Date(domain.createdAt),
            updatedAt: formatISO8601Date(domain.updatedAt)
        )
    }

    // MARK: - Architecture Pattern Helpers

    private func mapArchitecturePatterns(
        _ data: [ArchitecturePatternData]
    ) -> [DetectedArchitecturePattern] {
        data.compactMap { item in
            guard let pattern = ArchitecturePattern(rawValue: item.pattern) else {
                return nil
            }
            return DetectedArchitecturePattern(
                pattern: pattern,
                confidence: item.confidence,
                evidence: []
            )
        }
    }

    private func mapArchitecturePatternsToData(
        _ patterns: [DetectedArchitecturePattern]
    ) -> [ArchitecturePatternData] {
        patterns.map { pattern in
            ArchitecturePatternData(
                pattern: pattern.pattern.rawValue,
                confidence: pattern.confidence
            )
        }
    }

    // MARK: - CodeFile Mapping

    public func fileToDomain(_ record: SupabaseCodeFileRecord) -> CodeFile {
        CodeFile(
            id: UUID(uuidString: record.id) ?? UUID(),
            codebaseId: UUID(uuidString: record.codebaseId) ?? UUID(),
            projectId: UUID(uuidString: record.projectId) ?? UUID(),
            filePath: record.filePath,
            fileHash: record.fileHash,
            fileSize: record.fileSize,
            language: record.language.flatMap { ProgrammingLanguage(rawValue: $0) },
            isParsed: record.isParsed,
            parseError: record.parseError,
            createdAt: parseISO8601Date(record.createdAt) ?? Date(),
            updatedAt: parseISO8601Date(record.updatedAt) ?? Date()
        )
    }

    func fileToRecord(_ domain: CodeFile) -> SupabaseCodeFileRecord {
        SupabaseCodeFileRecord(
            id: domain.id.uuidString,
            codebaseId: domain.codebaseId.uuidString,
            projectId: domain.projectId.uuidString,
            filePath: domain.filePath,
            fileHash: domain.fileHash,
            fileSize: domain.fileSize,
            language: domain.language?.rawValue,
            isParsed: domain.isParsed,
            parseError: domain.parseError,
            createdAt: formatISO8601Date(domain.createdAt),
            updatedAt: formatISO8601Date(domain.updatedAt)
        )
    }

    // MARK: - CodeChunk Mapping

    public func chunkToDomain(_ record: SupabaseCodeChunkRecord) -> CodeChunk {
        CodeChunk(
            id: UUID(uuidString: record.id) ?? UUID(),
            fileId: UUID(uuidString: record.fileId) ?? UUID(),
            codebaseId: UUID(uuidString: record.codebaseId) ?? UUID(),
            projectId: UUID(uuidString: record.projectId) ?? UUID(),
            filePath: record.filePath,
            content: record.content,
            contentHash: record.contentHash,
            startLine: record.startLine,
            endLine: record.endLine,
            chunkType: ChunkType(rawValue: record.chunkType) ?? .other,
            language: ProgrammingLanguage(rawValue: record.language) ?? .swift,
            symbols: record.symbols,
            imports: record.imports,
            tokenCount: record.tokenCount,
            createdAt: parseISO8601Date(record.createdAt) ?? Date()
        )
    }

    func chunkToRecord(_ domain: CodeChunk) -> SupabaseCodeChunkRecord {
        SupabaseCodeChunkRecord(
            id: domain.id.uuidString,
            fileId: domain.fileId.uuidString,
            codebaseId: domain.codebaseId.uuidString,
            projectId: domain.projectId.uuidString,
            filePath: domain.filePath,
            content: domain.content,
            contentHash: domain.contentHash,
            startLine: domain.startLine,
            endLine: domain.endLine,
            chunkType: domain.chunkType.rawValue,
            language: domain.language.rawValue,
            symbols: domain.symbols,
            imports: domain.imports,
            tokenCount: domain.tokenCount,
            createdAt: formatISO8601Date(domain.createdAt)
        )
    }

    // MARK: - CodeEmbedding Mapping

    public func embeddingToDomain(_ record: SupabaseCodeEmbeddingRecord) -> CodeEmbedding {
        CodeEmbedding(
            id: UUID(uuidString: record.id) ?? UUID(),
            chunkId: UUID(uuidString: record.chunkId) ?? UUID(),
            projectId: UUID(uuidString: record.projectId) ?? UUID(),
            embedding: record.embedding,
            model: record.model,
            embeddingVersion: 1,
            createdAt: parseISO8601Date(record.createdAt) ?? Date()
        )
    }

    func embeddingToRecord(_ domain: CodeEmbedding) -> SupabaseCodeEmbeddingRecord {
        SupabaseCodeEmbeddingRecord(
            id: domain.id.uuidString,
            chunkId: domain.chunkId.uuidString,
            projectId: domain.projectId.uuidString,
            embedding: domain.embedding,
            model: domain.model,
            createdAt: formatISO8601Date(domain.createdAt)
        )
    }

}
