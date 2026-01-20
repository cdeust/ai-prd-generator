import Foundation

/// Port for tracking mockup analysis
/// Following Interface Segregation - focused on mockup analysis tracing
public protocol MockupAnalysisTrackerPort: Sendable {
    /// Record a mockup analysis
    func recordAnalysis(_ trace: MockupAnalysisTrace) async throws

    /// Update prd_id for mockup traces when mockup is associated with PRD
    func updatePrdId(mockupId: UUID, prdId: UUID) async throws

    /// Find analyses for a PRD
    func findByPrdId(_ prdId: UUID) async throws -> [MockupAnalysisTrace]

    /// Find analyses for a mockup
    func findByMockupId(_ mockupId: UUID) async throws -> [MockupAnalysisTrace]
}
