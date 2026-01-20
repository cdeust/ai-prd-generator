import Foundation

/// ReAct action definition
public struct ReActAction: Sendable {
    public let actionType: ReActActionType
    public let query: String
    public let parameters: [String: String]

    public init(
        actionType: ReActActionType,
        query: String,
        parameters: [String: String] = [:]
    ) {
        self.actionType = actionType
        self.query = query
        self.parameters = parameters
    }
}
