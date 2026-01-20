import Foundation

/// Cost classification for resolution strategies.
public enum StrategyCost: String, Codable, Sendable {
    /// Low computational cost (< 1 second)
    case low

    /// Medium computational cost (1-5 seconds)
    case medium

    /// High cost (requires user interaction)
    case high
}
