import Foundation

/// Storage configuration parsed from environment
struct ConfigurationStorageConfig {
    let type: StorageType
    let path: URL
    let databaseURL: String?
}
