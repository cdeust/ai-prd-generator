import Foundation

/// Temporary holder for step components during parsing
/// Used by PlanParser
struct StepComponents: Sendable {
    var description: String?
    var requires: String?
    var produces: String?
    var challenges: String?
}
