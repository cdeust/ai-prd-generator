import AIPRDMetaPromptingEngine
import Foundation

/// Result of meta-prompting engine creation
enum MetaPromptingEngineResult {
    case engine(MetaPromptingEngineProtocol)
    case degraded

    var isEngineMode: Bool {
        if case .engine = self { return true }
        return false
    }

    /// Get the underlying engine or nil if degraded
    var engine: MetaPromptingEngineProtocol? {
        if case .engine(let engine) = self { return engine }
        return nil
    }
}
