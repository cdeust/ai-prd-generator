import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Mapper for Codebase domain entities from PostgreSQL rows
/// Single Responsibility: Data transformation between PostgreSQL rows and Domain
public struct PostgreSQLCodebaseMapper: Sendable {
    public init() {}

    // MARK: - Codebase Mapping

    public func codebaseToDomain(_ row: [String: Any]) throws -> Codebase {
        guard let id = row["id"] as? String,
              let userId = row["user_id"] as? String,
              let name = row["name"] as? String,
              let repositoryUrl = row["repository_url"] as? String,
              let indexingStatus = row["indexing_status"] as? String,
              let createdAt = row["created_at"] as? String else {
            throw PostgreSQLError.missingRequiredColumn("codebase mapping")
        }

        return Codebase(
            id: UUID(uuidString: id) ?? UUID(),
            userId: UUID(uuidString: userId) ?? UUID(),
            name: name,
            repositoryUrl: repositoryUrl,
            localPath: row["local_path"] as? String,
            indexingStatus: IndexingStatus(rawValue: indexingStatus) ?? .pending,
            totalFiles: row["total_files"] as? Int ?? 0,
            indexedFiles: row["indexed_files"] as? Int ?? 0,
            detectedLanguages: row["detected_languages"] as? [String] ?? [],
            createdAt: parseISO8601Date(createdAt) ?? Date(),
            lastIndexedAt: (row["last_indexed_at"] as? String).flatMap { parseISO8601Date($0) }
        )
    }

    public func codebaseToDict(_ domain: Codebase) -> [String: Any] {
        var dict: [String: Any] = [
            "id": domain.id.uuidString,
            "user_id": domain.userId.uuidString,
            "name": domain.name,
            "repository_url": domain.repositoryUrl as Any,
            "indexing_status": domain.indexingStatus.rawValue,
            "total_files": domain.totalFiles,
            "indexed_files": domain.indexedFiles,
            "detected_languages": domain.detectedLanguages,
            "created_at": formatISO8601Date(domain.createdAt),
            "updated_at": formatISO8601Date(Date())
        ]

        if let localPath = domain.localPath {
            dict["local_path"] = localPath
        }

        if let lastIndexedAt = domain.lastIndexedAt {
            dict["last_indexed_at"] = formatISO8601Date(lastIndexedAt)
        }

        return dict
    }

    // MARK: - CodebaseProject Mapping

    public func projectToDomain(_ row: [String: Any]) throws -> CodebaseProject {
        guard let id = row["id"] as? String,
              let codebaseId = row["codebase_id"] as? String,
              let name = row["name"] as? String,
              let repositoryUrl = row["repository_url"] as? String,
              let branch = row["branch"] as? String,
              let indexingStatus = row["indexing_status"] as? String,
              let createdAt = row["created_at"] as? String,
              let updatedAt = row["updated_at"] as? String else {
            throw PostgreSQLError.missingRequiredColumn("project mapping")
        }

        let architecturePatterns = (row["architecture_patterns"] as? [[String: Any]])
            .flatMap { mapArchitecturePatterns($0) } ?? []

        return CodebaseProject(
            id: UUID(uuidString: id) ?? UUID(),
            codebaseId: UUID(uuidString: codebaseId) ?? UUID(),
            name: name,
            repositoryUrl: repositoryUrl,
            branch: branch,
            commitSha: row["commit_sha"] as? String,
            indexingStatus: IndexingStatus(rawValue: indexingStatus) ?? .pending,
            indexingStartedAt: (row["indexing_started_at"] as? String).flatMap { parseISO8601Date($0) },
            indexingCompletedAt: (row["indexing_completed_at"] as? String).flatMap { parseISO8601Date($0) },
            indexingError: row["indexing_error"] as? String,
            totalFiles: row["total_files"] as? Int ?? 0,
            totalChunks: row["total_chunks"] as? Int ?? 0,
            totalTokens: row["total_tokens"] as? Int ?? 0,
            merkleRootHash: row["merkle_root_hash"] as? String,
            detectedLanguages: row["detected_languages"] as? [String] ?? [],
            detectedFrameworks: row["detected_frameworks"] as? [String] ?? [],
            architecturePatterns: architecturePatterns,
            createdAt: parseISO8601Date(createdAt) ?? Date(),
            updatedAt: parseISO8601Date(updatedAt) ?? Date()
        )
    }

    public func projectToDict(_ domain: CodebaseProject) -> [String: Any] {
        var dict: [String: Any] = [
            "id": domain.id.uuidString,
            "codebase_id": domain.codebaseId.uuidString,
            "name": domain.name,
            "repository_url": domain.repositoryUrl,
            "branch": domain.branch,
            "indexing_status": domain.indexingStatus.rawValue,
            "total_files": domain.totalFiles,
            "total_chunks": domain.totalChunks,
            "total_tokens": domain.totalTokens,
            "detected_languages": domain.detectedLanguages,
            "detected_frameworks": domain.detectedFrameworks,
            "architecture_patterns": mapArchitecturePatternsToData(domain.architecturePatterns),
            "created_at": formatISO8601Date(domain.createdAt),
            "updated_at": formatISO8601Date(domain.updatedAt)
        ]

        if let commitSha = domain.commitSha {
            dict["commit_sha"] = commitSha
        }

        if let indexingStartedAt = domain.indexingStartedAt {
            dict["indexing_started_at"] = formatISO8601Date(indexingStartedAt)
        }

        if let indexingCompletedAt = domain.indexingCompletedAt {
            dict["indexing_completed_at"] = formatISO8601Date(indexingCompletedAt)
        }

        if let indexingError = domain.indexingError {
            dict["indexing_error"] = indexingError
        }

        if let merkleRootHash = domain.merkleRootHash {
            dict["merkle_root_hash"] = merkleRootHash
        }

        return dict
    }

    // MARK: - Date Helpers

    internal func parseISO8601Date(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    internal func formatISO8601Date(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    // MARK: - Architecture Pattern Helpers

    private func mapArchitecturePatterns(_ data: [[String: Any]]) -> [DetectedArchitecturePattern] {
        data.compactMap { item in
            guard let pattern = item["pattern"] as? String,
                  let confidence = item["confidence"] as? Double,
                  let archPattern = ArchitecturePattern(rawValue: pattern) else {
                return nil
            }
            return DetectedArchitecturePattern(
                pattern: archPattern,
                confidence: confidence,
                evidence: []
            )
        }
    }

    private func mapArchitecturePatternsToData(_ patterns: [DetectedArchitecturePattern]) -> [[String: Any]] {
        patterns.map { pattern in
            [
                "pattern": pattern.pattern.rawValue,
                "confidence": pattern.confidence
            ]
        }
    }
}
