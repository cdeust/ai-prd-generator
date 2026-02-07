import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Extension for embedding and vector search operations
/// Single Responsibility: Vector embedding persistence and similarity search
extension PostgreSQLCodebaseRepository {
    // MARK: - Embedding Operations

    public func saveEmbeddings(_ embeddings: [CodeEmbedding], projectId: UUID) async throws {
        let records = embeddings.map { embeddingToRecord($0) }
        _ = try await databaseClient.insertBatch(table: "code_embeddings", values: records)
    }

    public func findSimilarChunks(
        projectId: UUID,
        queryEmbedding: [Float],
        limit: Int,
        similarityThreshold: Float
    ) async throws -> [SimilarCodeChunk] {
        let parameters: [String: Any] = [
            "project_id": projectId.uuidString,
            "query_embedding": queryEmbedding,
            "match_threshold": similarityThreshold,
            "match_count": limit
        ]

        let data = try await databaseClient.callRPC(
            function: "match_code_chunks",
            parameters: parameters
        )

        let rows = try decodeRows(from: data)
        return try rows.map { try mapper.similarChunkToDomain($0) }
    }

    public func searchFiles(
        in codebaseId: UUID,
        embedding: [Float],
        limit: Int,
        similarityThreshold: Float?
    ) async throws -> [(file: CodeFile, similarity: Float)] {
        let parameters: [String: Any] = [
            "codebase_id": codebaseId.uuidString,
            "query_embedding": embedding,
            "match_threshold": similarityThreshold ?? 0.7,
            "match_count": limit
        ]

        let data = try await databaseClient.callRPC(
            function: "match_code_files",
            parameters: parameters
        )

        let rows = try decodeRows(from: data)
        return rows.compactMap { row -> (file: CodeFile, similarity: Float)? in
            guard let fileData = row["file"] as? [String: Any],
                  let similarity = row["similarity"] as? Double else {
                return nil
            }
            guard let file = try? mapper.fileToDomain(fileData) else {
                return nil
            }
            return (file: file, similarity: Float(similarity))
        }
    }

    // MARK: - Merkle Tree Operations

    public func saveMerkleRoot(projectId: UUID, rootHash: String) async throws {
        let updateDict: [String: Any] = [
            "merkle_root_hash": rootHash,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        _ = try await databaseClient.update(
            table: "codebase_projects",
            values: updateDict,
            whereClause: "id = $1",
            parameters: [projectId.uuidString]
        )
    }

    public func getMerkleRoot(projectId: UUID) async throws -> String? {
        let data = try await databaseClient.select(
            from: "codebase_projects",
            columns: ["merkle_root_hash"],
            whereClause: "id = $1",
            parameters: [projectId.uuidString]
        )
        let rows = try decodeRows(from: data)
        return rows.first?["merkle_root_hash"] as? String
    }

    public func saveMerkleNodes(_ nodes: [MerkleNode], projectId: UUID) async throws {
        guard !nodes.isEmpty else { return }
        let records = traverseAndConvertNodes(nodes, projectId: projectId)
        guard !records.isEmpty else { return }
        _ = try await databaseClient.insertBatch(table: "merkle_nodes", values: records)
    }

    public func getMerkleNodes(projectId: UUID) async throws -> [MerkleNode] {
        let data = try await databaseClient.select(
            from: "merkle_nodes",
            columns: nil,
            whereClause: "project_id = $1 ORDER BY level, position",
            parameters: [projectId.uuidString]
        )
        let rows = try decodeRows(from: data)
        return reconstructMerkleTree(from: rows)
    }

    // MARK: - Private Helpers

    private func reconstructMerkleTree(from rows: [[String: Any]]) -> [MerkleNode] {
        var nodesById: [UUID: MerkleNode] = [:]

        // First pass: create leaf nodes
        for row in rows {
            guard let id = row["id"] as? String,
                  let uuid = UUID(uuidString: id),
                  let hash = row["hash"] as? String,
                  row["left_child_id"] == nil,
                  row["right_child_id"] == nil else {
                continue
            }
            let filePath = row["file_path"] as? String ?? ""
            nodesById[uuid] = .leaf(id: uuid, hash: hash, filePath: filePath)
        }

        // Second pass: create branch nodes
        var changed = true
        while changed {
            changed = false
            for row in rows {
                guard let id = row["id"] as? String,
                      let uuid = UUID(uuidString: id),
                      nodesById[uuid] == nil,
                      let hash = row["hash"] as? String,
                      let leftId = row["left_child_id"] as? String,
                      let rightId = row["right_child_id"] as? String,
                      let leftUUID = UUID(uuidString: leftId),
                      let rightUUID = UUID(uuidString: rightId),
                      let left = nodesById[leftUUID],
                      let right = nodesById[rightUUID] else {
                    continue
                }
                nodesById[uuid] = .branch(id: uuid, hash: hash, left: left, right: right)
                changed = true
            }
        }

        // Return root nodes
        let rootIds = rows
            .filter { ($0["level"] as? Int) == 0 }
            .compactMap { ($0["id"] as? String).flatMap { UUID(uuidString: $0) } }
        return rootIds.compactMap { nodesById[$0] }
    }

    private func traverseAndConvertNodes(_ nodes: [MerkleNode], projectId: UUID) -> [PGMerkleNodeRecord] {
        var records: [PGMerkleNodeRecord] = []
        var seenIds: Set<UUID> = []
        var queue: [(node: MerkleNode, level: Int, position: Int)] = []

        for (i, node) in nodes.enumerated() {
            queue.append((node, 0, i))
        }

        while !queue.isEmpty {
            let (node, level, position) = queue.removeFirst()
            guard !seenIds.contains(node.id) else { continue }
            seenIds.insert(node.id)

            switch node {
            case .leaf(let id, let hash, _):
                records.append(createLeafRecord(
                    id: id, hash: hash, projectId: projectId, level: level, position: position
                ))

            case .branch(let id, let hash, let left, let right):
                records.append(createBranchRecord(
                    id: id, hash: hash, left: left, right: right,
                    projectId: projectId, level: level, position: position
                ))
                queue.append((left, level + 1, position * 2))
                queue.append((right, level + 1, position * 2 + 1))
            }
        }
        return records
    }

    private func createLeafRecord(
        id: UUID, hash: String, projectId: UUID, level: Int, position: Int
    ) -> PGMerkleNodeRecord {
        PGMerkleNodeRecord(
            id: id.uuidString,
            projectId: projectId.uuidString,
            chunkId: nil,
            hash: hash,
            leftChildId: nil,
            rightChildId: nil,
            level: level,
            position: position,
            createdAt: Date()
        )
    }

    private func createBranchRecord(
        id: UUID, hash: String, left: MerkleNode, right: MerkleNode,
        projectId: UUID, level: Int, position: Int
    ) -> PGMerkleNodeRecord {
        PGMerkleNodeRecord(
            id: id.uuidString,
            projectId: projectId.uuidString,
            chunkId: nil,
            hash: hash,
            leftChildId: left.id.uuidString,
            rightChildId: right.id.uuidString,
            level: level,
            position: position,
            createdAt: Date()
        )
    }

    private func embeddingToRecord(_ embedding: CodeEmbedding) -> [String: Any] {
        [
            "id": embedding.id.uuidString,
            "chunk_id": embedding.chunkId.uuidString,
            "project_id": embedding.projectId.uuidString,
            "embedding": embedding.embedding,
            "model": embedding.model,
            "created_at": ISO8601DateFormatter().string(from: embedding.createdAt)
        ]
    }
}
