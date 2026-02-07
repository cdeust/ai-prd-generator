import AIPRDSharedUtilities
import Foundation

/// Represents an extracted logical unit from code
public struct LogicalUnit: Sendable {
    public let name: String
    public let content: String
    public let startLine: Int
    public let endLine: Int

    public init(name: String, content: String, startLine: Int, endLine: Int) {
        self.name = name
        self.content = content
        self.startLine = startLine
        self.endLine = endLine
    }
}
