import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// In-memory verification evidence repository (no persistence)
/// Used for testing and non-database storage modes
/// Single Responsibility: No-op implementation for verification evidence
public struct InMemoryVerificationEvidenceRepository: VerificationEvidenceRepositoryPort {

    public init() {}

    public func saveVerification(
        _ result: UnifiedVerificationResult,
        entityType: VerificationEntityType,
        entityId: UUID,
        verificationType: VerificationType
    ) async throws -> UUID {
        // No-op: Return random UUID for compatibility
        return UUID()
    }

    public func findVerificationById(_ id: UUID) async throws -> UnifiedVerificationResult? {
        // No-op: Return nil
        return nil
    }

    public func findVerificationsForEntity(
        type: VerificationEntityType,
        entityId: UUID
    ) async throws -> [UnifiedVerificationResult] {
        // No-op: Return empty array
        return []
    }

    public func findLatestVerification(
        for entityType: VerificationEntityType,
        entityId: UUID
    ) async throws -> UnifiedVerificationResult? {
        // No-op: Return nil
        return nil
    }

    public func getVerificationStatistics(
        for verificationType: VerificationType,
        since date: Date
    ) async throws -> VerificationStatistics {
        // Return empty statistics
        return VerificationStatistics(
            verificationType: verificationType,
            totalVerifications: 0,
            averageScore: 0.0,
            averageConfidence: 0.0,
            verificationRate: 0.0,
            averageDurationMs: nil
        )
    }

    public func getJudgePerformance(
        provider: String?,
        model: String?
    ) async throws -> [JudgePerformanceMetrics] {
        // Return empty array
        return []
    }

    public func getOptimalQuestions(
        for verificationType: VerificationType,
        limit: Int
    ) async throws -> [VerificationQuestion] {
        // Return empty array
        return []
    }

    public func getRefinementEffectiveness(
        for entityType: VerificationEntityType
    ) async throws -> RefinementEffectivenessMetrics {
        // Return empty metrics
        return RefinementEffectivenessMetrics(
            entityType: entityType,
            totalRefinements: 0,
            averageScoreImprovement: 0.0,
            successRate: 0.0,
            refinementsByAttempt: [:]
        )
    }

    public func getRecentEvidence(
        entityId: UUID,
        entityType: VerificationEntityType,
        limit: Int
    ) async throws -> [UnifiedVerificationResult] {
        // No-op: Return empty array
        return []
    }
}
