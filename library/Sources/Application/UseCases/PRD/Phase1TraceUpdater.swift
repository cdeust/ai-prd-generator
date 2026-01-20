import Foundation
import Domain

/// Handles updating Phase 1 intelligence traces with PRD ID after creation
/// Single Responsibility: Update traces collected before PRD existed
struct Phase1TraceUpdater: Sendable {
    private let intelligenceTracker: IntelligenceTrackerService?
    private let mockupAssociation: MockupAssociationService?

    init(
        intelligenceTracker: IntelligenceTrackerService?,
        mockupAssociation: MockupAssociationService?
    ) {
        self.intelligenceTracker = intelligenceTracker
        self.mockupAssociation = mockupAssociation
    }

    /// Update all Phase 1 traces (RAG, mockups, clarifications, LLM interactions) with PRD ID
    func updateTraces(
        prdId: UUID,
        codebaseId: UUID?,
        mockupFileIds: [String]?,
        clarificationQuestionIds: [UUID]
    ) async {
        await updateRAGTraces(prdId: prdId, codebaseId: codebaseId)
        await updateMockupTraces(prdId: prdId, fileIds: mockupFileIds)
        await updateClarificationTraces(prdId: prdId, questionIds: clarificationQuestionIds)
        await updateLLMInteractionTraces(prdId: prdId)
    }

    private func updateRAGTraces(prdId: UUID, codebaseId: UUID?) async {
        guard let codebaseId = codebaseId else { return }
        do {
            try await intelligenceTracker?.updateRAGRetrievalPrdId(codebaseId: codebaseId, prdId: prdId)
            print("✅ [Intelligence] Updated RAG traces with PRD ID")
        } catch {
            print("❌ [Intelligence] Failed to update RAG traces: \(error)")
        }
    }

    private func updateMockupTraces(prdId: UUID, fileIds: [String]?) async {
        guard let fileIds = fileIds else { return }
        try? await mockupAssociation?.associateMockups(fileIds: fileIds, withPRDDocument: prdId)
        for fileIdString in fileIds {
            guard let mockupId = UUID(uuidString: fileIdString) else { continue }
            do {
                try await intelligenceTracker?.updateMockupAnalysisPrdId(mockupId: mockupId, prdId: prdId)
                print("✅ [Intelligence] Updated mockup trace: \(mockupId)")
            } catch {
                print("❌ [Intelligence] Failed to update mockup trace: \(error)")
            }
        }
    }

    private func updateClarificationTraces(prdId: UUID, questionIds: [UUID]) async {
        print("🔍 [DEBUG] updateClarificationTraces called with:")
        print("   - PRD ID: \(prdId)")
        print("   - Question IDs count: \(questionIds.count)")
        print("   - Question IDs: \(questionIds)")
        print("   - intelligenceTracker is nil: \(intelligenceTracker == nil)")

        guard let tracker = intelligenceTracker else {
            print("❌ [CRITICAL] intelligenceTracker is NIL - cannot update clarifications!")
            return
        }

        for questionId in questionIds {
            print("🔄 [DEBUG] Updating clarification trace for question: \(questionId)")
            do {
                try await tracker.updateClarificationPrdId(questionId: questionId, prdId: prdId)
                print("✅ [Intelligence] Updated clarification trace: \(questionId)")
            } catch {
                print("❌ [Intelligence] Failed to update clarification trace \(questionId): \(error)")
            }
        }
        if !questionIds.isEmpty {
            print("📊 [Intelligence] Updated \(questionIds.count) clarification traces with PRD ID")
        } else {
            print("⚠️ [WARNING] No question IDs provided to update!")
        }
    }

    private func updateLLMInteractionTraces(prdId: UUID) async {
        guard let tracker = intelligenceTracker else {
            print("⚠️ [Intelligence] No intelligenceTracker - LLM traces NOT updated")
            return
        }

        do {
            try await tracker.updatePhase1LLMInteractionPrdId(prdId: prdId)
            print("✅ [Intelligence] Updated Phase 1 LLM interaction traces with PRD ID")
        } catch {
            print("❌ [Intelligence] Failed to update LLM interaction traces: \(error)")
        }
    }
}
