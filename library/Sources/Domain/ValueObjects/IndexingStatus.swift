import Foundation

/// Value object representing codebase indexing status
public enum IndexingStatus: String, Sendable, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case failed = "failed"

    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    public var isTerminal: Bool {
        self == .completed || self == .failed
    }
}
