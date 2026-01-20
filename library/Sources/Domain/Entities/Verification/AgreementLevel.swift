import Foundation

/// Level of agreement among judges
/// Used to assess consensus quality
public enum AgreementLevel: String, Sendable, Codable, Equatable {
    case high = "high"
    case medium = "medium"
    case low = "low"

    /// Determine agreement level from score variance
    /// Low variance = high agreement
    public static func from(scoreVariance: Double) -> AgreementLevel {
        if scoreVariance < 0.1 {
            return .high
        } else if scoreVariance < 0.25 {
            return .medium
        } else {
            return .low
        }
    }
}
