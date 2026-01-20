import Foundation
import Domain

/// Maps PRD sections between domain and database records
/// Single Responsibility: Section record transformation
struct SupabasePRDSectionMapper {
    private let jsonCoders = PRDJSONCoders()

    func sectionToRecord(
        _ section: PRDSection,
        documentId: UUID,
        orderIndex: Int
    ) -> SupabasePRDSectionRecord {
        let dateFormatter = ISO8601DateFormatter()
        let now = dateFormatter.string(from: Date())

        return SupabasePRDSectionRecord(
            id: section.id.uuidString.lowercased(),
            prdDocumentId: documentId.uuidString.lowercased(),
            sectionType: section.type.rawValue,
            title: section.title,
            content: section.content,
            orderIndex: orderIndex,
            openapiSpecJson: jsonCoders.encodeOpenAPISpec(section.openAPISpec),
            testSuiteJson: jsonCoders.encodeTestSuite(section.testSuite),
            thinkingStrategy: section.thinkingStrategy,
            confidence: section.confidence,
            assumptionsJson: jsonCoders.encodeAssumptions(section.assumptions),
            createdAt: now,
            updatedAt: now
        )
    }

    func sectionToDomain(_ record: SupabasePRDSectionRecord) -> PRDSection {
        let assumptions = jsonCoders.decodeAssumptions(record.assumptionsJson)
        let openAPISpec = jsonCoders.decodeOpenAPISpec(record.openapiSpecJson)
        let testSuite = jsonCoders.decodeTestSuite(record.testSuiteJson)

        return PRDSection(
            id: UUID(uuidString: record.id) ?? UUID(),
            type: record.sectionType.flatMap { SectionType(rawValue: $0) } ?? .overview,
            title: record.title ?? "Untitled",
            content: record.content ?? "",
            order: record.orderIndex ?? 0,
            confidence: record.confidence,
            assumptions: assumptions,
            thinkingStrategy: record.thinkingStrategy,
            openAPISpec: openAPISpec,
            testSuite: testSuite
        )
    }
}
