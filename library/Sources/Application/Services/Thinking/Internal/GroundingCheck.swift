import Foundation

/// Internal grounding check result
/// Following Single Responsibility: Represents grounding assessment
struct GroundingCheck {
    let isGrounded: Bool
    let score: Double
    let reason: String
}
