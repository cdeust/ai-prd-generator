import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Helper for updating codebase indexing status
enum CodebaseStatusUpdater {
    /// Update codebase status after indexing operation
    static func updateStatus(
        codebaseId: UUID,
        status: IndexingStatus,
        repository: CodebaseRepositoryPort
    ) async throws {
        guard let codebase = try await repository.getCodebase(by: codebaseId) else { return }

        let updated = Codebase(
            id: codebase.id,
            userId: codebase.userId,
            name: codebase.name,
            repositoryUrl: codebase.repositoryUrl,
            localPath: codebase.localPath,
            indexingStatus: status,
            totalFiles: codebase.totalFiles,
            indexedFiles: codebase.indexedFiles,
            detectedLanguages: codebase.detectedLanguages,
            createdAt: codebase.createdAt,
            lastIndexedAt: status == .completed ? Date() : codebase.lastIndexedAt
        )

        _ = try await repository.updateCodebase(updated)
    }
}
