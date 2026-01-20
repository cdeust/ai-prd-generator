import Foundation

/// Mockup image data transfer object
public struct MockupImage: Sendable, Equatable, Identifiable {
    /// Unique identifier
    public let id: UUID

    /// Binary image data (PNG or JPEG)
    public let data: Data

    /// MIME type (image/png, image/jpeg)
    public let mimeType: String

    /// Optional image name
    public let name: String?

    /// Optional metadata
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        data: Data,
        mimeType: String,
        name: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.data = data
        self.mimeType = mimeType
        self.name = name
        self.metadata = metadata
    }

    /// Image size in bytes
    public var sizeInBytes: Int {
        data.count
    }

    /// Check if image is PNG
    public var isPNG: Bool {
        mimeType == "image/png"
    }

    /// Check if image is JPEG
    public var isJPEG: Bool {
        mimeType == "image/jpeg" || mimeType == "image/jpg"
    }
}
