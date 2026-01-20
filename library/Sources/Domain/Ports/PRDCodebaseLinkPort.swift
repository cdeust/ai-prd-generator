import Foundation

/// Port for linking PRD requests to codebase projects
/// Domain defines the interface, Infrastructure implements
public protocol PRDCodebaseLinkPort: Sendable {
    /// Link a PRD request to a codebase project
    func linkPRDToCodebase(prdRequestId: UUID, codebaseProjectId: UUID) async throws

    /// Link a codebase to a PRD (alternative naming for clarity)
    func linkCodebaseToPRD(prdId: UUID, codebaseId: UUID) async throws

    /// Get codebase project linked to a PRD request
    func getCodebaseForPRD(prdRequestId: UUID) async throws -> CodebaseProject?

    /// Get all codebases linked to a PRD
    func getCodebasesForPRD(prdRequestId: UUID) async throws -> [CodebaseProject]

    /// Get all PRDs linked to a codebase
    func getPRDsForCodebase(codebaseProjectId: UUID) async throws -> [UUID]

    /// Unlink PRD from codebase
    func unlinkPRDFromCodebase(prdRequestId: UUID, codebaseProjectId: UUID) async throws

    /// Unlink all codebases from a PRD
    func unlinkAllCodebasesFromPRD(prdRequestId: UUID) async throws

    /// Check if PRD is linked to codebase
    func isLinked(prdRequestId: UUID, codebaseProjectId: UUID) async throws -> Bool
}
