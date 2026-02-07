import Foundation

/// Result of fetching multiple file contents from a repository
struct FetchedFileContents {
    let chunks: [String]
    let paths: [String]
}
