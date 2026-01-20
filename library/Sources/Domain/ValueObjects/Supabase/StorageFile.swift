import Foundation

/// Storage file metadata
/// Domain value object for file information
public struct StorageFile: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let size: Int
    public let mimeType: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: String,
        name: String,
        size: Int,
        mimeType: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.mimeType = mimeType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
