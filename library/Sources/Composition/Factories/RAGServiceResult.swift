import AIPRDOrchestrationEngine
import AIPRDRAGEngine
import Application
import Foundation

/// RAG service result - either full engine or degraded fallback
enum RAGServiceResult {
    case engine(RAGEngineProtocol)
    case degraded(DegradedRAGService)

    var isEngineMode: Bool {
        if case .engine = self { return true }
        return false
    }

    /// Get the underlying RAG engine (works for both modes)
    var engine: RAGEngineProtocol {
        switch self {
        case .engine(let engine): return engine
        case .degraded(let service): return service
        }
    }
}
