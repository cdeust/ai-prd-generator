import AIPRDOrchestrationEngine
import AIPRDStrategyEngine
import Foundation

/// Result of strategy engine creation
enum StrategyEngineResult {
    case full(StrategyEngineAdapter)
    case degraded(StrategyEngineAdapter)

    var isFullMode: Bool {
        if case .full = self { return true }
        return false
    }

    /// Get the adapter (available in both modes)
    var adapter: StrategyEngineAdapter {
        switch self {
        case .full(let adapter): return adapter
        case .degraded(let adapter): return adapter
        }
    }

    /// Whether this is the licensed (full) version
    var isLicensed: Bool {
        isFullMode
    }
}
