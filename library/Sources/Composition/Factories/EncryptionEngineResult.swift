import AIPRDEncryptionEngine
import Foundation

/// Result of encryption engine creation (full or degraded)
public enum EncryptionEngineResult: Sendable {
    case engine(EncryptionEngineProtocol)
    case degraded

    /// Get the engine if available, nil if degraded
    public var engine: EncryptionEngineProtocol? {
        switch self {
        case .engine(let engine): return engine
        case .degraded: return nil
        }
    }

    /// Whether this is a degraded result
    public var isDegraded: Bool {
        switch self {
        case .engine: return false
        case .degraded: return true
        }
    }
}
