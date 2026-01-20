import Foundation

/// Port for Supabase storage (file uploads)
/// Domain interface for cloud storage operations
public protocol SupabaseStoragePort: Sendable {
    /// Upload file to Supabase storage
    /// - Parameters:
    ///   - data: File data
    ///   - bucket: Storage bucket name
    ///   - path: File path in bucket
    ///   - contentType: MIME type
    /// - Returns: Public URL
    func upload(
        data: Data,
        bucket: String,
        path: String,
        contentType: String?
    ) async throws -> String

    /// Download file from Supabase storage
    /// - Parameters:
    ///   - bucket: Storage bucket
    ///   - path: File path
    /// - Returns: File data
    func download(bucket: String, path: String) async throws -> Data

    /// Delete file from storage
    /// - Parameters:
    ///   - bucket: Storage bucket
    ///   - path: File path
    func delete(bucket: String, path: String) async throws

    /// List files in bucket
    /// - Parameters:
    ///   - bucket: Storage bucket
    ///   - path: Directory path
    /// - Returns: List of file metadata
    func list(bucket: String, path: String) async throws -> [StorageFile]

    /// Get public URL for file
    /// - Parameters:
    ///   - bucket: Storage bucket
    ///   - path: File path
    /// - Returns: Public URL
    func getPublicURL(bucket: String, path: String) -> String

    /// Create signed URL for private file access
    /// - Parameters:
    ///   - bucket: Storage bucket
    ///   - path: File path
    ///   - expiresIn: Expiration time in seconds
    /// - Returns: Signed URL
    func createSignedURL(
        bucket: String,
        path: String,
        expiresIn: Int
    ) async throws -> String
}
