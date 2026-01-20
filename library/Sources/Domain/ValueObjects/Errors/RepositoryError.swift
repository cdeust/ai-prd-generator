import Foundation

/// Repository errors
/// Following Single Responsibility Principle - encapsulates repository errors
public enum RepositoryError: Error {
    case notFound(String)
    case saveFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case queryFailed(String)
}
