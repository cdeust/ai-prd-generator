import Foundation

/// Expanded query result from query expansion
/// Following Single Responsibility: Represents query expansion outcome
public struct ExpandedQuery: Sendable {
    public let original: String
    public let hypotheticalDocument: String
    public let decomposedQueries: [String]
    public let allQueries: [String]

    public init(
        original: String,
        hypotheticalDocument: String,
        decomposedQueries: [String],
        allQueries: [String]
    ) {
        self.original = original
        self.hypotheticalDocument = hypotheticalDocument
        self.decomposedQueries = decomposedQueries
        self.allQueries = allQueries
    }
}
