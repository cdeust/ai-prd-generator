import Foundation

/// Port for tracking PRD performance metrics
/// Following Interface Segregation - focused on metrics tracking
public protocol PerformanceMetricsTrackerPort: Sendable {
    /// Save or update performance metrics
    func saveMetrics(_ metrics: PRDPerformanceMetrics) async throws

    /// Find metrics for a PRD
    func findByPrdId(_ prdId: UUID) async throws -> PRDPerformanceMetrics?

    /// Update user feedback
    func updateUserFeedback(
        prdId: UUID,
        satisfactionScore: Double,
        wouldRecommend: Bool,
        feedbackText: String?
    ) async throws

    /// Get average metrics by strategy
    func getAverageByStrategy(_ strategy: String) async throws -> PRDPerformanceMetrics?
}
