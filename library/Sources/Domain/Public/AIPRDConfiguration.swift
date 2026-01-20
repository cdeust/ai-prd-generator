import Foundation

/// Configuration for AI PRD Library
/// Public value object for client configuration
public struct AIPRDConfiguration: Sendable {
    public let supabaseURL: String
    public let supabaseKey: String
    public let enableOfflineMode: Bool
    public let enableDebugLogging: Bool

    public init(
        supabaseURL: String,
        supabaseKey: String,
        enableOfflineMode: Bool = false,
        enableDebugLogging: Bool = false
    ) {
        self.supabaseURL = supabaseURL
        self.supabaseKey = supabaseKey
        self.enableOfflineMode = enableOfflineMode
        self.enableDebugLogging = enableDebugLogging
    }
}
