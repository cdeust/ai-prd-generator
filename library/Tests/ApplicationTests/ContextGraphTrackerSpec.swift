import AIPRDOrchestrationEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import XCTest
@testable import Application
@testable import Domain

/// Real tests for ContextGraphTracker implementation
/// Tests the ACTUAL actor methods with proper async/await
final class ContextGraphTrackerSpec: XCTestCase {

    // MARK: - Test: Cycle Detection - Acyclic Graph

    func testCycleDetection_acyclicGraph_returnsfalse() async throws {
        // Given: Linear chain A -> B -> C (no cycle)
        let tracker = ContextGraphTracker()

        let nodeA = ContextNode(type: .thought(thoughtType: .observation), content: "A")
        let nodeB = ContextNode(type: .thought(thoughtType: .observation), content: "B")
        let nodeC = ContextNode(type: .thought(thoughtType: .observation), content: "C")

        await tracker.addNode(nodeA)
        await tracker.addNode(nodeB)
        await tracker.addNode(nodeC)

        await tracker.link(from: nodeA.id, to: nodeB.id, relationship: .dependsOn)
        await tracker.link(from: nodeB.id, to: nodeC.id, relationship: .dependsOn)

        // When: Check if we can reach A from C (should be false - no back edge)
        let hasCycle = await tracker.hasCircularDependency(from: nodeA.id, to: nodeC.id)

        // Then: No cycle should be detected
        XCTAssertFalse(hasCycle, "Acyclic graph should not detect cycles")
    }

    // MARK: - Test: Cycle Detection - Cyclic Graph

    func testCycleDetection_cyclicGraph_returnsTrue() async throws {
        // Given: Cycle A -> B -> C -> A
        let tracker = ContextGraphTracker()

        let nodeA = ContextNode(type: .thought(thoughtType: .observation), content: "A")
        let nodeB = ContextNode(type: .thought(thoughtType: .observation), content: "B")
        let nodeC = ContextNode(type: .thought(thoughtType: .observation), content: "C")

        await tracker.addNode(nodeA)
        await tracker.addNode(nodeB)
        await tracker.addNode(nodeC)

        await tracker.link(from: nodeA.id, to: nodeB.id, relationship: .dependsOn)
        await tracker.link(from: nodeB.id, to: nodeC.id, relationship: .dependsOn)
        await tracker.link(from: nodeC.id, to: nodeA.id, relationship: .dependsOn)  // Creates cycle

        // When: Check for cycle
        let hasCycle = await tracker.hasCircularDependency(from: nodeA.id, to: nodeA.id)

        // Then: Cycle should be detected
        XCTAssertTrue(hasCycle, "Cyclic graph should detect cycles")
    }

    // MARK: - Test: Context Path

    func testGetContextPath_returnsNodesInOrder() async throws {
        // Given: Three nodes added in sequence
        let tracker = ContextGraphTracker()

        let node1 = ContextNode(type: .thought(thoughtType: .observation), content: "First")
        let node2 = ContextNode(type: .thought(thoughtType: .analysis), content: "Second")
        let node3 = ContextNode(type: .thought(thoughtType: .conclusion), content: "Third")

        await tracker.addNode(node1)
        await tracker.addNode(node2)
        await tracker.addNode(node3)

        // When: Get context path
        let path = await tracker.getContextPath()

        // Then: Should return all nodes in order
        XCTAssertEqual(path.count, 3)
        XCTAssertEqual(path[0].id, node1.id)
        XCTAssertEqual(path[1].id, node2.id)
        XCTAssertEqual(path[2].id, node3.id)
    }

    // MARK: - Test: Pruning

    func testPruning_removesOldNodes() async throws {
        // Given: Many nodes (more than keepRecent threshold)
        let tracker = ContextGraphTracker()

        var allNodes: [ContextNode] = []
        for i in 0..<50 {
            let node = ContextNode(
                type: .thought(thoughtType: .observation),
                content: "Node \(i)"
            )
            await tracker.addNode(node)
            allNodes.append(node)
        }

        // When: Prune keeping only 20 most recent
        await tracker.pruneIrrelevantContext(keepRecent: 20)

        // Then: Should have only 20 nodes left
        let path = await tracker.getContextPath()
        XCTAssertEqual(path.count, 20, "Should keep only 20 most recent nodes")

        // Validate we kept the LAST 20 nodes (most recent)
        let lastNode = allNodes[49]
        XCTAssertEqual(path.last?.id, lastNode.id, "Should keep most recent node")
    }

    // MARK: - Test: Relevant Context Scoring

    func testGetRelevantContext_ranksRecentNodesHigher() async throws {
        // Given: Old and recent nodes with same content
        let tracker = ContextGraphTracker()

        let oldNode = ContextNode(
            type: .thought(thoughtType: .observation),
            content: "test query relevant"
        )

        let recentNode = ContextNode(
            type: .thought(thoughtType: .observation),
            content: "test query relevant"
        )

        await tracker.addNode(oldNode)
        // Add some spacing nodes
        for i in 0..<5 {
            let spacing = ContextNode(
                type: .thought(thoughtType: .observation),
                content: "spacing \(i)"
            )
            await tracker.addNode(spacing)
        }
        await tracker.addNode(recentNode)

        // When: Get relevant context for query
        let relevant = await tracker.getRelevantContext(for: "test query", maxNodes: 10)

        // Then: Recent node should score higher (appears earlier in results)
        let recentIndex = relevant.firstIndex { $0.id == recentNode.id }
        let oldIndex = relevant.firstIndex { $0.id == oldNode.id }

        XCTAssertNotNil(recentIndex, "Recent node should be in results")
        XCTAssertNotNil(oldIndex, "Old node should be in results")

        if let recentIdx = recentIndex, let oldIdx = oldIndex {
            XCTAssertLessThan(recentIdx, oldIdx, "Recent node should rank higher than old node")
        }
    }

    // MARK: - Test: Relationship Strength Scoring

    func testGetRelevantContext_ranksConnectedNodesHigher() async throws {
        // Given: Two nodes, one highly connected, one isolated
        let tracker = ContextGraphTracker()

        let connectedNode = ContextNode(
            type: .thought(thoughtType: .observation),
            content: "connected test"
        )

        let isolatedNode = ContextNode(
            type: .thought(thoughtType: .observation),
            content: "isolated test"
        )

        let supportNode1 = ContextNode(type: .thought(thoughtType: .observation), content: "support1")
        let supportNode2 = ContextNode(type: .thought(thoughtType: .observation), content: "support2")

        await tracker.addNode(connectedNode)
        await tracker.addNode(isolatedNode)
        await tracker.addNode(supportNode1)
        await tracker.addNode(supportNode2)

        // Create strong connections to connectedNode
        await tracker.link(from: supportNode1.id, to: connectedNode.id, relationship: .supports, strength: 0.9)
        await tracker.link(from: supportNode2.id, to: connectedNode.id, relationship: .supports, strength: 0.9)

        // When: Get relevant context
        let relevant = await tracker.getRelevantContext(for: "test", maxNodes: 10)

        // Then: Connected node should rank higher
        let connectedIndex = relevant.firstIndex { $0.id == connectedNode.id }
        let isolatedIndex = relevant.firstIndex { $0.id == isolatedNode.id }

        XCTAssertNotNil(connectedIndex, "Connected node should be in results")
        XCTAssertNotNil(isolatedIndex, "Isolated node should be in results")

        if let connectedIdx = connectedIndex, let isolatedIdx = isolatedIndex {
            XCTAssertLessThan(connectedIdx, isolatedIdx, "Connected node should rank higher")
        }
    }

    // MARK: - Test: Content Relevance (Jaccard Similarity)

    func testGetRelevantContext_ranksRelevantContentHigher() async throws {
        // Given: Nodes with different content relevance (added in reverse order of relevance)
        let tracker = ContextGraphTracker()

        // Add irrelevant first (will be oldest)
        let irrelevant = ContextNode(
            type: .thought(thoughtType: .observation),
            content: "python django framework"  // No matching terms
        )
        await tracker.addNode(irrelevant)

        // Add spacing to increase recency gap
        for i in 0..<5 {
            let spacing = ContextNode(
                type: .thought(thoughtType: .observation),
                content: "spacing \(i)"
            )
            await tracker.addNode(spacing)
        }

        // Add highly relevant last (will be most recent)
        let highlyRelevant = ContextNode(
            type: .thought(thoughtType: .observation),
            content: "swift async await concurrency actor"  // Many matching terms
        )
        await tracker.addNode(highlyRelevant)

        // When: Query for Swift concurrency
        let relevant = await tracker.getRelevantContext(for: "swift async await", maxNodes: 10)

        // Then: Highly relevant (recent + relevant content) should outrank irrelevant (old + no matches)
        let highlyRelevantIndex = relevant.firstIndex { $0.id == highlyRelevant.id }
        let irrelevantIndex = relevant.firstIndex { $0.id == irrelevant.id }

        XCTAssertNotNil(highlyRelevantIndex, "Highly relevant should be in results")
        XCTAssertNotNil(irrelevantIndex, "Irrelevant should be in results")

        if let highIdx = highlyRelevantIndex, let irIdx = irrelevantIndex {
            XCTAssertLessThan(highIdx, irIdx, "Highly relevant should rank higher than irrelevant")
        }
    }

    // MARK: - Test: Edge Cases

    func testCycleDetection_selfLoop_returnsTrue() async throws {
        // Given: Node with edge to itself
        let tracker = ContextGraphTracker()

        let node = ContextNode(type: .thought(thoughtType: .observation), content: "self")

        await tracker.addNode(node)
        await tracker.link(from: node.id, to: node.id, relationship: .refines)  // Self-loop

        // When: Check for cycle
        let hasCycle = await tracker.hasCircularDependency(from: node.id, to: node.id)

        // Then: Should detect self-loop as cycle
        XCTAssertTrue(hasCycle, "Self-loop should be detected as cycle")
    }

    func testPruning_belowThreshold_doesNotPrune() async throws {
        // Given: Few nodes (below 2x keepRecent threshold)
        let tracker = ContextGraphTracker()

        for i in 0..<10 {
            let node = ContextNode(
                type: .thought(thoughtType: .observation),
                content: "Node \(i)"
            )
            await tracker.addNode(node)
        }

        // When: Try to prune with keepRecent=20
        await tracker.pruneIrrelevantContext(keepRecent: 20)

        // Then: Should not prune (10 < 20*2)
        let path = await tracker.getContextPath()
        XCTAssertEqual(path.count, 10, "Should not prune when below 2x threshold")
    }
}
