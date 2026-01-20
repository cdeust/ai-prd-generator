import Foundation

/// Port for storing and querying verification evidence
/// Single Responsibility: Verification evidence persistence
/// Enables meta-learning through historical verification analysis
public protocol VerificationEvidenceRepositoryPort: Sendable {
    /// Save complete verification result with all evidence
    /// Links to entity being verified (PRD, session, etc.)
    func saveVerification(
        _ result: CoVVerificationResult,
        entityType: VerificationEntityType,
        entityId: UUID,
        verificationType: VerificationType
    ) async throws -> UUID

    /// Find verification by ID
    func findVerificationById(_ id: UUID) async throws -> CoVVerificationResult?

    /// Find all verifications for an entity
    /// Returns verification history in chronological order
    func findVerificationsForEntity(
        type: VerificationEntityType,
        entityId: UUID
    ) async throws -> [CoVVerificationResult]

    /// Find latest verification for an entity
    func findLatestVerification(
        for entityType: VerificationEntityType,
        entityId: UUID
    ) async throws -> CoVVerificationResult?

    /// Query historical verification statistics
    /// Enables meta-learning: "What's typical score for this verification type?"
    func getVerificationStatistics(
        for verificationType: VerificationType,
        since: Date
    ) async throws -> VerificationStatistics

    /// Get judge performance metrics
    /// Enables meta-learning: "Which judges are most reliable?"
    func getJudgePerformance(
        provider: String?,
        model: String?
    ) async throws -> [JudgePerformanceMetrics]

    /// Get most effective verification questions
    /// Enables meta-learning: "What questions produce best consensus?"
    func getOptimalQuestions(
        for verificationType: VerificationType,
        limit: Int
    ) async throws -> [VerificationQuestion]

    /// Track refinement effectiveness
    /// Enables meta-learning: "Do refinements actually improve scores?"
    func getRefinementEffectiveness(
        for entityType: VerificationEntityType
    ) async throws -> RefinementEffectivenessMetrics
}
