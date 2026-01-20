import Foundation

/// Errors thrown by circuit breaker
public enum CircuitBreakerError: Error, Sendable {
    case circuitOpen(retryAfter: TimeInterval)
}

