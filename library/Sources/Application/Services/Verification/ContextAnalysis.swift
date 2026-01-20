import Foundation

/// Analysis of PRD generation context
internal struct ContextAnalysis {
    enum Complexity {
        case low, medium, high
    }

    let complexity: Complexity
    let domainType: String
    let requiresClarification: Bool
}
