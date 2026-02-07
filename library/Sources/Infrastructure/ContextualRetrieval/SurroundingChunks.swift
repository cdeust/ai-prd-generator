import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Container for chunks before and after main chunk
/// Extracted per Rule 9 (no nested types)
public struct SurroundingChunks: Sendable {
    public let before: [CodeChunk]
    public let after: [CodeChunk]

    public init(before: [CodeChunk], after: [CodeChunk]) {
        self.before = before
        self.after = after
    }

    public var totalChunks: Int {
        before.count + after.count
    }

    public var isEmpty: Bool {
        before.isEmpty && after.isEmpty
    }
}
