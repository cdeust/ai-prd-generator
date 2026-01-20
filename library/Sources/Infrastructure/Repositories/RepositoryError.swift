import Foundation

/// Errors that can occur during repository operations
enum RepositoryError: Error {
    case invalidQuery(String)
    case saveFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case notFound(String)
}
