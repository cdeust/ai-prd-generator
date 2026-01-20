import Foundation

/// Internal consistency check result
/// Following Single Responsibility: Represents consistency assessment
struct ConsistencyCheck {
    let isConsistent: Bool
    let reason: String
}
