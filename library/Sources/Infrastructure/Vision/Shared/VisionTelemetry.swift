import Foundation

/// Telemetry and monitoring for vision analysis operations
public actor VisionTelemetry: Sendable {
    // MARK: - Properties

    private var metrics: [String: ProviderMetrics] = [:]

    // MARK: - Public Interface

    /// Record successful analysis
    public func recordSuccess(
        provider: String,
        duration: TimeInterval,
        componentCount: Int,
        confidence: Double
    ) {
        var providerMetrics = getOrCreateMetrics(for: provider)
        providerMetrics.recordSuccess(
            duration: duration,
            componentCount: componentCount,
            confidence: confidence
        )
        metrics[provider] = providerMetrics
    }

    /// Record failed analysis
    public func recordFailure(
        provider: String,
        error: Error,
        duration: TimeInterval
    ) {
        var providerMetrics = getOrCreateMetrics(for: provider)
        providerMetrics.recordFailure(
            error: error,
            duration: duration
        )
        metrics[provider] = providerMetrics
    }

    /// Get metrics for a specific provider
    public func getMetrics(for provider: String) -> ProviderMetrics {
        getOrCreateMetrics(for: provider)
    }

    /// Get metrics for all providers
    public func getAllMetrics() -> [String: ProviderMetrics] {
        metrics
    }

    /// Reset all metrics
    public func reset() {
        metrics.removeAll()
    }

    // MARK: - Private Helpers

    private func getOrCreateMetrics(for provider: String) -> ProviderMetrics {
        if let existing = metrics[provider] {
            return existing
        }

        let new = ProviderMetrics(provider: provider)
        metrics[provider] = new
        return new
    }
}

