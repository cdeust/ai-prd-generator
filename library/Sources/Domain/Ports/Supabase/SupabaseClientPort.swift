import Foundation

/// Combined Supabase client port
/// Domain interface aggregating all Supabase capabilities
public protocol SupabaseClientPort: SupabaseDatabasePort, SupabaseStoragePort, SupabaseRealtimePort {
    /// Initialize client with configuration
    init(url: String, apiKey: String, schema: String)

    /// Database client
    var database: SupabaseDatabasePort { get }

    /// Storage client
    var storage: SupabaseStoragePort { get }

    /// Realtime client
    var realtime: SupabaseRealtimePort { get }
}
