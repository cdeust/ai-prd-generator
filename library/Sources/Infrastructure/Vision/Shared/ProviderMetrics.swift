import Foundation

/// Metrics for a specific vision provider
public struct ProviderMetrics: Sendable {
    // MARK: - Properties

    public let provider: String
    public private(set) var totalRequests: Int = 0
    public private(set) var successfulRequests: Int = 0
    public private(set) var failedRequests: Int = 0
    public private(set) var totalDuration: TimeInterval = 0
    public private(set) var totalComponents: Int = 0
    public private(set) var totalConfidence: Double = 0
    public private(set) var errorCounts: [String: Int] = [:]

    // MARK: - Computed Properties

    public var successRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(successfulRequests) / Double(totalRequests)
    }

    public var averageDuration: TimeInterval {
        guard totalRequests > 0 else { return 0 }
        return totalDuration / Double(totalRequests)
    }

    public var averageComponents: Double {
        guard successfulRequests > 0 else { return 0 }
        return Double(totalComponents) / Double(successfulRequests)
    }

    public var averageConfidence: Double {
        guard successfulRequests > 0 else { return 0 }
        return totalConfidence / Double(successfulRequests)
    }

    // MARK: - Initialization

    init(provider: String) {
        self.provider = provider
    }

    // MARK: - Mutation Methods

    mutating func recordSuccess(
        duration: TimeInterval,
        componentCount: Int,
        confidence: Double
    ) {
        totalRequests += 1
        successfulRequests += 1
        totalDuration += duration
        totalComponents += componentCount
        totalConfidence += confidence
    }

    mutating func recordFailure(
        error: Error,
        duration: TimeInterval
    ) {
        totalRequests += 1
        failedRequests += 1
        totalDuration += duration

        let errorType = String(describing: type(of: error))
        errorCounts[errorType, default: 0] += 1
    }
}

