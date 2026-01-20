import Foundation
import Domain

/// Extension for embedding and vector search operations
/// Single Responsibility: Vector embedding persistence and similarity search
extension SupabaseCodebaseRepository {
    // MARK: - Embedding Operations

    public func saveEmbeddings(_ embeddings: [CodeEmbedding], projectId: UUID) async throws {
        let records = embeddings.map { mapper.embeddingToRecord($0) }
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

        let results = try decode([SupabaseVectorSearchResult].self, from: data)
        return results.map { result in
            SimilarCodeChunk(
                chunk: mapper.chunkToDomain(result.chunk),
                similarity: result.similarity
            )
        }
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

        let results = try decode([FileVectorSearchResult].self, from: data)
        return results.map { result in
            (file: mapper.fileToDomain(result.file), similarity: result.similarity)
        }
    }

    // MARK: - Merkle Tree Operations

    public func saveMerkleRoot(projectId: UUID, rootHash: String) async throws {
        let updateData = MerkleRootUpdate(merkleRootHash: rootHash, updatedAt: Date())
        let filter = QueryFilter(field: "id", operation: .equals, value: projectId.uuidString)
        _ = try await databaseClient.update(
            table: "codebase_projects",
            values: updateData,
            matching: filter
        )
    }

    public func getMerkleRoot(projectId: UUID) async throws -> String? {
        let filter = QueryFilter(field: "id", operation: .equals, value: projectId.uuidString)
        let data = try await databaseClient.select(
            from: "codebase_projects",
            columns: ["merkle_root_hash"],
            filter: filter
        )
        let projects = try decode([SupabaseCodebaseProjectRecord].self, from: data)
        return projects.first?.merkleRootHash
    }

    public func saveMerkleNodes(_ nodes: [MerkleNode], projectId: UUID) async throws {
        guard !nodes.isEmpty else { return }

        // Traverse from root node(s) and build records with proper level/position
        // Track seen IDs to avoid duplicates (nodes may reference same children)
        var seenIds: Set<UUID> = []
        var result: [MerkleNodeRecord] = []
        var queue: [(node: MerkleNode, level: Int, position: Int)] = []

        // Add root nodes to queue
        for (i, node) in nodes.enumerated() {
            // Only add if this is a root (level 0 node) we haven't seen
            if !seenIds.contains(node.id) {
                queue.append((node, 0, i))
            }
        }

        while !queue.isEmpty {
            let (node, level, position) = queue.removeFirst()

            // Skip if already processed
            guard !seenIds.contains(node.id) else { continue }
            seenIds.insert(node.id)

            let record = MerkleNodeRecord(from: node, projectId: projectId, level: level, position: position)
            result.append(record)

            if case .branch(_, _, let left, let right) = node {
                if !seenIds.contains(left.id) {
                    queue.append((left, level + 1, position * 2))
                }
                if !seenIds.contains(right.id) {
                    queue.append((right, level + 1, position * 2 + 1))
                }
            }
        }

        guard !result.isEmpty else { return }
        _ = try await databaseClient.insertBatch(table: "merkle_nodes", values: result)
    }

    public func getMerkleNodes(projectId: UUID) async throws -> [MerkleNode] {
        let filter = QueryFilter(field: "project_id", operation: .equals, value: projectId.uuidString)
        let data = try await databaseClient.select(from: "merkle_nodes", columns: nil, filter: filter)
        let records = try decode([MerkleNodeRecord].self, from: data)

        // Reconstruct tree from flat records
        return try reconstructMerkleTree(from: records)
    }

    private func reconstructMerkleTree(from records: [MerkleNodeRecord]) throws -> [MerkleNode] {
        var nodesById: [UUID: MerkleNode] = [:]

        // Sort by level descending (leaves first at highest level, then branches)
        let sortedRecords = records.sorted { $0.level > $1.level }

        for record in sortedRecords {
            guard let nodeId = UUID(uuidString: record.id) else { continue }

            let isLeaf = record.leftHash == nil && record.rightHash == nil
            if isLeaf {
                // Leaf node - filePath not stored, use empty string
                nodesById[nodeId] = .leaf(id: nodeId, hash: record.nodeHash, filePath: "")
            } else if let leftHash = record.leftHash, let rightHash = record.rightHash {
                // Branch node - find children by hash
                let left = nodesById.values.first { $0.hash == leftHash }
                let right = nodesById.values.first { $0.hash == rightHash }

                if let left = left, let right = right {
                    nodesById[nodeId] = .branch(id: nodeId, hash: record.nodeHash, left: left, right: right)
                }
            }
        }

        return Array(nodesById.values)
    }
}
