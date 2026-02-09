import AIPRDSharedUtilities
import AIPRDSharedUtilities
import Foundation

/// Result of initiating repository indexing
public struct IndexingResult: Sendable {
    public let codebase: Codebase
    public let isNewIndexing: Bool

    public init(codebase: Codebase, isNewIndexing: Bool) {
        self.codebase = codebase
        self.isNewIndexing = isNewIndexing
    }
}
