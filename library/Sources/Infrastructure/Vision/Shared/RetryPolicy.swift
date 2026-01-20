import Foundation

/// Retry policy with exponential backoff for API calls
public struct RetryPolicy: Sendable {
    public let maxAttempts: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let multiplier: Double

    public init(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 10.0,
        multiplier: Double = 2.0
    ) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.multiplier = multiplier
    }

    public func delay(for attempt: Int) -> TimeInterval {
        let calculatedDelay = baseDelay * pow(multiplier, Double(attempt))
        return min(calculatedDelay, maxDelay)
    }

    public func shouldRetry(
        attempt: Int,
        error: Error
    ) -> Bool {
        guard attempt < maxAttempts else {
            return false
        }

        return isRetryableError(error)
    }

    private func isRetryableError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            return isRetryableURLError(urlError)
        }

        return false
    }

    private func isRetryableURLError(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut, .cannotConnectToHost, .networkConnectionLost:
            return true
        case .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }
}

