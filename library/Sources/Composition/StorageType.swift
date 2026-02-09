import AIPRDSharedUtilities
import Foundation

/// Storage types for standalone skill (no cloud dependencies)
public enum StorageType: String, Sendable {
    case memory      // In-memory only (no persistence)
    case filesystem  // Local file storage
    case postgres    // Local PostgreSQL (Docker or native)
}
