import Foundation

/// Compression techniques
public enum CompressionTechnique: String, Sendable, Codable {
    case semantic
    case metaToken
    case contextual
    case tokenSkip
    case llmlingua
    case hybrid
}
