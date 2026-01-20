import Foundation
import Domain

/// Holds tracking metadata for a section to be persisted AFTER section is saved to database
/// This avoids foreign key constraint violations by deferring tracking until section_id exists
struct SectionTrackingMetadata: Sendable {
    let sectionId: UUID
    let prdId: UUID
    let sectionType: SectionType
    let strategy: ThinkingStrategy
    let prompt: String
    let content: String
    let latencyMs: Int

    init(
        sectionId: UUID,
        prdId: UUID,
        sectionType: SectionType,
        strategy: ThinkingStrategy,
        prompt: String,
        content: String,
        latencyMs: Int
    ) {
        self.sectionId = sectionId
        self.prdId = prdId
        self.sectionType = sectionType
        self.strategy = strategy
        self.prompt = prompt
        self.content = content
        self.latencyMs = latencyMs
    }
}
