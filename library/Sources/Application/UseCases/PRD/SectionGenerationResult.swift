import Foundation
import Domain

/// Result of generating a single PRD section
/// Following 3R's: Named struct instead of large tuple for Readability, Reliability, Reusability
struct SectionGenerationResult: Sendable {
    let section: PRDSection
    let updatedClarifications: String
    let strategy: ThinkingStrategy?
    let trackingMetadata: SectionTrackingMetadata?
}
