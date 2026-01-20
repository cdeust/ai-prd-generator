import Foundation

/// Repository type
/// Following Single Responsibility Principle - represents repository type
public enum RepositoryType: String, Sendable {
    case github
    case gitlab
    case bitbucket
    case local
}
