import Foundation

/// Result of executing a ReAct action
public struct ReActActionResult: Sendable {
    public let success: Bool
    public let summary: String
    public let data: String
    public let metadata: [String: String]

    public init(
        success: Bool,
        summary: String,
        data: String,
        metadata: [String: String] = [:]
    ) {
        self.success = success
        self.summary = summary
        self.data = data
        self.metadata = metadata
    }
}
