import Foundation

/// ReAct action types
public enum ReActActionType: String, Sendable {
    case searchCodebase
    case analyze
    case conclude
}
