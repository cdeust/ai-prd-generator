import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Handles status updates for codebase indexing operations
struct IndexCodebaseStatusUpdater: Sendable {
    private let codebaseRepository: CodebaseRepositoryPort

    init(codebaseRepository: CodebaseRepositoryPort) {
        self.codebaseRepository = codebaseRepository
    }

    func updateProjectStatus(
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

    func updateCodebaseStatus(
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

    func buildCodebaseContext(projectId: UUID) async throws -> String? {
        guard let project = try await codebaseRepository.findProjectById(projectId),
              let codebase = try await codebaseRepository.getCodebase(by: project.codebaseId) else {
            return nil
        }

        var context = "Codebase: \(codebase.name)"

        if let url = codebase.repositoryUrl {
            context += " (Repository: \(url))"
        }

        if !codebase.detectedLanguages.isEmpty {
            context += "\nLanguages: \(codebase.detectedLanguages.joined(separator: ", "))"
        }

        if !project.detectedFrameworks.isEmpty {
            context += "\nFrameworks: \(project.detectedFrameworks.joined(separator: ", "))"
        }

        if !project.architecturePatterns.isEmpty {
            let patterns = project.architecturePatterns.map { $0.pattern.rawValue }
            context += "\nArchitecture: \(patterns.joined(separator: ", "))"
        }

        return context
    }
}
