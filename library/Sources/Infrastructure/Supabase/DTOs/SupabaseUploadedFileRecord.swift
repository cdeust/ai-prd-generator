import Foundation

/// Supabase Uploaded File Record
/// Maps to uploaded_files table schema (000_complete_schema.sql)
/// Tracks file uploads for lifecycle management and cleanup
public struct SupabaseUploadedFileRecord: Codable, Sendable {
    let id: String
    let userId: String
    let fileName: String
    let fileSize: Int64
    let mimeType: String
    let fileType: String
    let storageBucket: String
    let storagePath: String
    let publicUrl: String?
    let checksum: String?
    let expiresAt: String?
    let associatedEntityType: String?
    let associatedEntityId: String?
    let uploadCompleted: Bool
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fileName = "file_name"
        case fileSize = "file_size"
        case mimeType = "mime_type"
        case fileType = "file_type"
        case storageBucket = "storage_bucket"
        case storagePath = "storage_path"
        case publicUrl = "public_url"
        case checksum
        case expiresAt = "expires_at"
        case associatedEntityType = "associated_entity_type"
        case associatedEntityId = "associated_entity_id"
        case uploadCompleted = "upload_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        fileName = try container.decode(String.self, forKey: .fileName)
        fileSize = try container.decode(Int64.self, forKey: .fileSize)
        mimeType = try container.decode(String.self, forKey: .mimeType)
        fileType = try container.decode(String.self, forKey: .fileType)
        storageBucket = try container.decode(String.self, forKey: .storageBucket)
        storagePath = try container.decode(String.self, forKey: .storagePath)
        publicUrl = try container.decodeIfPresent(String.self, forKey: .publicUrl)
        checksum = try container.decodeIfPresent(String.self, forKey: .checksum)
        expiresAt = try container.decodeIfPresent(String.self, forKey: .expiresAt)
        associatedEntityType = try container.decodeIfPresent(String.self, forKey: .associatedEntityType)
        associatedEntityId = try container.decodeIfPresent(String.self, forKey: .associatedEntityId)
        uploadCompleted = try container.decode(Bool.self, forKey: .uploadCompleted)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }

    /// Initializer for creating records to insert
    public init(
        id: String,
        userId: String,
        fileName: String,
        fileSize: Int64,
        mimeType: String,
        fileType: String,
        storageBucket: String,
        storagePath: String,
        publicUrl: String? = nil,
        checksum: String? = nil,
        expiresAt: String? = nil,
        associatedEntityType: String? = nil,
        associatedEntityId: String? = nil,
        uploadCompleted: Bool = true,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.userId = userId
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.fileType = fileType
        self.storageBucket = storageBucket
        self.storagePath = storagePath
        self.publicUrl = publicUrl
        self.checksum = checksum
        self.expiresAt = expiresAt
        self.associatedEntityType = associatedEntityType
        self.associatedEntityId = associatedEntityId
        self.uploadCompleted = uploadCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
