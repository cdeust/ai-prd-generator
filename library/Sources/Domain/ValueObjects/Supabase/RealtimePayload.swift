import Foundation

/// Realtime payload from subscription
/// Domain value object for change notifications
/// Note: Not Sendable due to [String: Any] - used only at infrastructure boundary
public struct RealtimePayload {
    public let eventType: RealtimeEvent
    public let table: String
    public let schema: String
    public let old: [String: Any]?
    public let new: [String: Any]?
    public let commitTimestamp: Date

    public init(
        eventType: RealtimeEvent,
        table: String,
        schema: String,
        old: [String: Any]? = nil,
        new: [String: Any]? = nil,
        commitTimestamp: Date
    ) {
        self.eventType = eventType
        self.table = table
        self.schema = schema
        self.old = old
        self.new = new
        self.commitTimestamp = commitTimestamp
    }
}
