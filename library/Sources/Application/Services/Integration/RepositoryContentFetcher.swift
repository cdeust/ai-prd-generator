import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Fetches repository file contents for indexing operations
enum RepositoryContentFetcher {
    /// Fetch all supported files from a repository with their content
    static func fetchFiles(
        repository: RemoteRepository,
        branch: String,
        connection: RepositoryConnection,
        codebaseId: UUID,
        projectId: UUID,
        fetcher: RepositoryFetcherPort
    ) async throws -> [(file: CodeFile, content: String)] {
        let fileTree = try await fetcher.fetchFileTree(
            repository: repository,
            branch: branch,
            connection: connection
        )

        let supportedFiles = fileTree.filter { $0.isSupported }
        var filesWithContent: [(file: CodeFile, content: String)] = []

        for node in supportedFiles {
            guard let fileData = try? await fetchSingleFile(
                repository: repository,
                filePath: node.path,
                branch: branch,
                connection: connection,
                codebaseId: codebaseId,
                projectId: projectId,
                fetcher: fetcher
            ) else { continue }
            filesWithContent.append(fileData)
        }

        return filesWithContent
    }

    private static func fetchSingleFile(
        repository: RemoteRepository,
        filePath: String,
        branch: String,
        connection: RepositoryConnection,
        codebaseId: UUID,
        projectId: UUID,
        fetcher: RepositoryFetcherPort
    ) async throws -> (file: CodeFile, content: String) {
        let content = try await fetcher.fetchFileContent(
            repository: repository,
            filePath: filePath,
            branch: branch,
            connection: connection
        )

        let codeFile = CodeFile(
            codebaseId: codebaseId,
            projectId: projectId,
            filePath: filePath,
            fileHash: computeHash(content),
            fileSize: content.utf8.count,
            language: detectLanguage(filePath)
        )

        return (codeFile, content)
    }

    static func computeHash(_ content: String) -> String {
        return String(content.utf8.count)
    }

    static func detectLanguage(_ path: String) -> ProgrammingLanguage {
        let ext = (path as NSString).pathExtension.lowercased()
        return ProgrammingLanguage.detectFromExtension(ext) ?? .unknown
    }
}
