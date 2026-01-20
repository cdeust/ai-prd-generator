import Foundation

/// Task complexity level
enum TaskComplexity: Sendable {
    case low
    case medium
    case high

    var multiplier: Double {
        switch self {
        case .low: return 0.8
        case .medium: return 1.0
        case .high: return 1.2
        }
    }
}
