import Foundation
import Domain

/// Result containing enriched request, answered question IDs, and collected answers
struct ClarificationEnrichmentResult: Sendable {
    let request: PRDRequest
    let answeredQuestionIds: [UUID]
    let collectedAnswers: [String]
}
