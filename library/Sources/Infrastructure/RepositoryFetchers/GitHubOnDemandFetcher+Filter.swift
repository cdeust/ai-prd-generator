import Foundation

/// File filtering helpers for on-demand fetching
extension GitHubOnDemandFetcher {
    private static let supportedExtensions = ["swift", "ts", "tsx", "js", "jsx", "py", "go", "rs", "java", "kt", "rb"]
    private static let excludedPathPatterns = ["test", "spec", "mock", "generated", "node_modules", ".build"]
    private static let mainSourcePatterns = ["src/", "sources/", "lib/", "app/"]

    func filterRelevantFiles(_ files: [GitHubTreeNodeDTO], query: String) -> [GitHubTreeNodeDTO] {
        let keywords = query.lowercased().split(separator: " ").map(String.init)

        return files.filter { file in
            isSupported(file) && !isExcluded(file) && isRelevant(file, keywords: keywords)
        }.sorted { $0.size < $1.size }
    }

    private func isSupported(_ file: GitHubTreeNodeDTO) -> Bool {
        let ext = (file.path as NSString).pathExtension.lowercased()
        return Self.supportedExtensions.contains(ext)
    }

    private func isExcluded(_ file: GitHubTreeNodeDTO) -> Bool {
        let lowercasePath = file.path.lowercased()
        return Self.excludedPathPatterns.contains { lowercasePath.contains($0) }
    }

    private func isRelevant(_ file: GitHubTreeNodeDTO, keywords: [String]) -> Bool {
        let lowercasePath = file.path.lowercased()
        let pathMatches = keywords.contains { lowercasePath.contains($0) }
        let isMainSource = Self.mainSourcePatterns.contains { lowercasePath.contains($0) }
        return pathMatches || isMainSource
    }
}
