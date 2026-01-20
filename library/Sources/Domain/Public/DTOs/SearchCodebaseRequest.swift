import Foundation

/// Public search request for codebase
/// Public DTO for codebase search requests
public struct SearchCodebaseRequest: Sendable {
    public let codebaseId: UUID
    public let query: String
    public let limit: Int

    public init(codebaseId: UUID, query: String, limit: Int = 10) {
        self.codebaseId = codebaseId
        self.query = query
        self.limit = limit
    }
}
