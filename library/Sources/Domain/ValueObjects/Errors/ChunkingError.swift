import Foundation

/// Chunking errors
public enum ChunkingError: Error, Sendable {
    case invalidInput(reason: String)
    case chunkingFailed(reason: String)
    case strategyNotSupported(ChunkingStrategy)
    case languageNotSupported(ProgrammingLanguage)
    case hierarchyInvalid(reason: String)
}
