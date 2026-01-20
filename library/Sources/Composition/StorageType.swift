import Foundation

/// Storage types
public enum StorageType: String, Sendable {
    case memory
    case filesystem
    case supabase
    case postgres
}
