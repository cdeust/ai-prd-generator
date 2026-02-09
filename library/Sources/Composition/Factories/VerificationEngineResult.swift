import AIPRDOrchestrationEngine
import AIPRDVerificationEngine
import Application
import Foundation

/// Result of verification engine creation
enum VerificationEngineResult {
    case unified(UnifiedVerificationEngine)
    case degraded(DegradedVerificationService)

    var isEngineMode: Bool {
        if case .unified = self { return true }
        return false
    }

    /// Get unified engine or nil if degraded
    var unifiedEngine: UnifiedVerificationEngine? {
        if case .unified(let engine) = self { return engine }
        return nil
    }
}
