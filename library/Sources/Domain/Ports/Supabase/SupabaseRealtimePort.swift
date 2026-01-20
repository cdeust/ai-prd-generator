import Foundation

/// Port for Supabase realtime subscriptions
/// Domain interface for database change notifications
public protocol SupabaseRealtimePort: Sendable {
    /// Subscribe to table changes
    /// - Parameters:
    ///   - table: Table name
    ///   - event: Event type (INSERT, UPDATE, DELETE)
    ///   - filter: Optional filter
    ///   - handler: Callback for changes
    func subscribe(
        to table: String,
        event: RealtimeEvent,
        filter: String?,
        handler: @escaping (RealtimePayload) async -> Void
    ) async throws -> String  // Returns subscription ID

    /// Unsubscribe from table
    /// - Parameter subscriptionId: Subscription ID
    func unsubscribe(subscriptionId: String) async throws

    /// Unsubscribe from all subscriptions for a table
    /// - Parameter table: Table name
    func unsubscribeAll(from table: String) async throws
}
