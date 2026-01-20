import Foundation

/// Circuit breaker pattern for vision API providers
/// Prevents cascading failures by temporarily disabling failing providers
public actor CircuitBreaker: Sendable {
    // MARK: - State

    public enum State: Sendable {
        case closed      // Normal operation
        case open        // Failures detected, reject requests
        case halfOpen    // Testing if service recovered
    }

    // MARK: - Configuration

    public struct Configuration: Sendable {
        public let failureThreshold: Int
        public let successThreshold: Int
        public let timeout: TimeInterval

        public init(
            failureThreshold: Int = 5,
            successThreshold: Int = 2,
            timeout: TimeInterval = 60.0
        ) {
            self.failureThreshold = failureThreshold
            self.successThreshold = successThreshold
            self.timeout = timeout
        }
    }

    // MARK: - Properties

    private let configuration: Configuration
    private var state: State = .closed
    private var failureCount: Int = 0
    private var successCount: Int = 0
    private var lastFailureTime: Date?

    // MARK: - Initialization

    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    // MARK: - Public Interface

    /// Check if request should be allowed
    public func shouldAllowRequest() async throws {
        switch state {
        case .closed:
            return

        case .open:
            try await checkIfShouldTransitionToHalfOpen()

        case .halfOpen:
            return
        }
    }

    /// Record successful request
    public func recordSuccess() {
        switch state {
        case .closed:
            failureCount = 0

        case .halfOpen:
            successCount += 1
            if successCount >= configuration.successThreshold {
                transitionToClosed()
            }

        case .open:
            break
        }
    }

    /// Record failed request
    public func recordFailure() {
        failureCount += 1
        successCount = 0
        lastFailureTime = Date()

        switch state {
        case .closed:
            if failureCount >= configuration.failureThreshold {
                transitionToOpen()
            }

        case .halfOpen:
            transitionToOpen()

        case .open:
            break
        }
    }

    /// Get current state
    public func getState() -> State {
        state
    }

    /// Reset circuit breaker
    public func reset() {
        state = .closed
        failureCount = 0
        successCount = 0
        lastFailureTime = nil
    }

    // MARK: - Private Helpers

    private func transitionToClosed() {
        state = .closed
        failureCount = 0
        successCount = 0
    }

    private func transitionToOpen() {
        state = .open
        successCount = 0
    }

    private func transitionToHalfOpen() {
        state = .halfOpen
        successCount = 0
    }

    private func checkIfShouldTransitionToHalfOpen() async throws {
        guard let lastFailure = lastFailureTime else {
            transitionToHalfOpen()
            return
        }

        let elapsed = Date().timeIntervalSince(lastFailure)
        if elapsed >= configuration.timeout {
            transitionToHalfOpen()
        } else {
            throw CircuitBreakerError.circuitOpen(
                retryAfter: configuration.timeout - elapsed
            )
        }
    }
}

