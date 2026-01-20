import Foundation

/// Confidence level categories
public enum ConfidenceLevel: String, Codable, Sendable {
    case veryHigh = "very_high"
    case high = "high"
    case medium = "medium"
    case low = "low"
}
