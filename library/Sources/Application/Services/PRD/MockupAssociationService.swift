import Foundation
import Domain

/// Service for associating mockups with PRD documents
struct MockupAssociationService: Sendable {
    private let repository: MockupRepositoryPort

    init(repository: MockupRepositoryPort) {
        self.repository = repository
    }

    /// Associate mockup files with a PRD document
    func associateMockups(
        fileIds: [String],
        withPRDDocument prdDocumentId: UUID
    ) async throws {
        guard !fileIds.isEmpty else { return }

        print("📎 Associating \(fileIds.count) mockups with PRD \(prdDocumentId)")

        for fileIdString in fileIds {
            try await associateSingleMockup(fileIdString, toPRD: prdDocumentId)
        }

        print("✅ Mockups associated with PRD")
    }

    private func associateSingleMockup(
        _ fileIdString: String,
        toPRD prdDocumentId: UUID
    ) async throws {
        guard let mockupId = UUID(uuidString: fileIdString),
              let mockup = try await repository.findById(mockupId) else {
            return
        }

        let updatedMockup = Mockup(
            id: mockup.id,
            prdDocumentId: prdDocumentId,
            name: mockup.name,
            description: mockup.description,
            type: mockup.type,
            source: mockup.source,
            fileUrl: mockup.fileUrl,
            fileSize: mockup.fileSize,
            width: mockup.width,
            height: mockup.height,
            extractedElements: mockup.extractedElements,
            annotations: mockup.annotations,
            analysisResult: mockup.analysisResult,
            orderIndex: mockup.orderIndex,
            createdAt: mockup.createdAt,
            updatedAt: Date()
        )

        _ = try await repository.update(updatedMockup)
    }
}
