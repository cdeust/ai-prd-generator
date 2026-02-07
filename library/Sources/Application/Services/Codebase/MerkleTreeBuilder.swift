import AIPRDSharedUtilities
import Foundation

/// Builds Merkle trees from code chunks for integrity verification
struct MerkleTreeBuilder: Sendable {
    private let hashingService: HashingPort

    init(hashingService: HashingPort) {
        self.hashingService = hashingService
    }

    func buildMerkleTree(from chunks: [CodeChunk]) -> MerkleTree {
        guard !chunks.isEmpty else {
            return MerkleTree(rootHash: "", rootNode: nil, totalFiles: 0)
        }

        var nodes: [MerkleNode] = chunks.map { chunk in
            .leaf(id: UUID(), hash: chunk.contentHash, filePath: chunk.filePath)
        }

        while nodes.count > 1 {
            var nextLevel: [MerkleNode] = []
            for i in stride(from: 0, to: nodes.count, by: 2) {
                if i + 1 < nodes.count {
                    let combinedHash = hashingService.sha256(of: nodes[i].hash + nodes[i + 1].hash)
                    let parent = MerkleNode.branch(
                        id: UUID(),
                        hash: combinedHash,
                        left: nodes[i],
                        right: nodes[i + 1]
                    )
                    nextLevel.append(parent)
                } else {
                    nextLevel.append(nodes[i])
                }
            }
            nodes = nextLevel
        }

        return MerkleTree(
            rootHash: nodes.first?.hash ?? "",
            rootNode: nodes.first,
            totalFiles: chunks.count
        )
    }

    func flattenMerkleTree(
        _ node: MerkleNode,
        projectId: UUID,
        level: Int = 0,
        position: Int = 0
    ) -> [MerkleNode] {
        var result: [MerkleNode] = [node]
        if case .branch(_, _, let left, let right) = node {
            result.append(
                contentsOf: flattenMerkleTree(
                    left,
                    projectId: projectId,
                    level: level + 1,
                    position: position * 2
                )
            )
            result.append(
                contentsOf: flattenMerkleTree(
                    right,
                    projectId: projectId,
                    level: level + 1,
                    position: position * 2 + 1
                )
            )
        }
        return result
    }
}
