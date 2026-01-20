import Foundation

/// Errors that can occur during codebase operations
public enum CodebaseError: Error, CustomStringConvertible, Sendable {
    case projectNotFound(UUID)
    case fileNotFound(UUID)
    case chunkNotFound(UUID)
    case embeddingNotFound(UUID)
    case noRelevantCode
    case embeddingFailed(String)
    case saveFailed
    case indexingFailed(String)
    case parsingFailed(String)
    case invalidCodebase(String)
    case invalidRepository(String)
    case merkleTreeError(String)

    public var description: String {
        switch self {
        case .projectNotFound(let id):
            return "Codebase project not found: \(id)"
        case .fileNotFound(let id):
            return "Code file not found: \(id)"
        case .chunkNotFound(let id):
            return "Code chunk not found: \(id)"
        case .embeddingNotFound(let id):
            return "Embedding not found: \(id)"
        case .noRelevantCode:
            return "No relevant code found in codebase"
        case .embeddingFailed(let message):
            return "Embedding generation failed: \(message)"
        case .saveFailed:
            return "Failed to save codebase data"
        case .indexingFailed(let message):
            return "Codebase indexing failed: \(message)"
        case .parsingFailed(let message):
            return "Code parsing failed: \(message)"
        case .invalidCodebase(let message):
            return "Invalid codebase: \(message)"
        case .invalidRepository(let message):
            return "Invalid repository: \(message)"
        case .merkleTreeError(let message):
            return "Merkle tree error: \(message)"
        }
    }
}
