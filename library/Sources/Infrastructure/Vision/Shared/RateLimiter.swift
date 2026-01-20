import Foundation

/// Rate limiter using token bucket algorithm
public actor RateLimiter: Sendable {
    private let capacity: Int
    private let refillRate: TimeInterval
    private var tokens: Int
    private var lastRefill: Date

    public init(requestsPerMinute: Int) {
        self.capacity = requestsPerMinute
        self.refillRate = 60.0 / Double(requestsPerMinute)
        self.tokens = requestsPerMinute
        self.lastRefill = Date()
    }

    public func waitForCapacity() async throws {
        refillTokens()

        while tokens == 0 {
            try await Task.sleep(
                nanoseconds: UInt64(refillRate * 1_000_000_000)
            )
            refillTokens()
        }

        tokens -= 1
    }

    private func refillTokens() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRefill)
        let tokensToAdd = Int(elapsed / refillRate)

        if tokensToAdd > 0 {
            tokens = min(capacity, tokens + tokensToAdd)
            lastRefill = now
        }
    }

    public func reset() {
        tokens = capacity
        lastRefill = Date()
    }

    public func availableTokens() -> Int {
        tokens
    }
}

