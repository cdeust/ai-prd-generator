import Foundation

/// Realtime event types
/// Domain enum for database change events
public enum RealtimeEvent: String, Sendable {
    case insert = "INSERT"
    case update = "UPDATE"
    case delete = "DELETE"
    case all = "*"
}
