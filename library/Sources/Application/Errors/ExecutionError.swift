import Foundation

/// Errors that can occur during strategy execution
enum ExecutionError: Error {
    case enhancementNotSupported(BaseStrategy)
}
