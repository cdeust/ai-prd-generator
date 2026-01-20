import Foundation

/// Chunking strategies
public enum ChunkingStrategy: Sendable, Codable, Equatable {
    case semantic
    case late
    case hierarchical
    case fixed(overlap: Int)
}
