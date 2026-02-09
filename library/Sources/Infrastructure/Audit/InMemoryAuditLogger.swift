import Foundation
import AIPRDSharedUtilities

/// In-memory audit logger for testing
public actor InMemoryAuditLogger: AuditLoggerPort {
    private var events: [AuditEvent] = []

    public init() {}

    public func log(_ event: AuditEvent) async {
        events.append(event)
    }

    public func queryEvents(since: Date, type: AuditEventType?) async -> [AuditEvent] {
        events.filter { event in
            event.timestamp >= since && (type == nil || event.type == type)
        }.sorted { $0.timestamp < $1.timestamp }
    }

    public func getAllEvents() -> [AuditEvent] {
        events
    }

    public func clear() {
        events.removeAll()
    }
}
