import Foundation

/// Status of gap resolution
public enum GapStatus: String, Codable, Sendable {
    /// Gap has been detected but not yet processed
    case detected

    /// Currently attempting to resolve the gap
    case resolving

    /// Gap has been successfully resolved
    case resolved

    /// Gap requires user input to resolve
    case requiresUser

    /// Gap resolution was skipped (low priority, informed assumption made)
    case skipped
}
