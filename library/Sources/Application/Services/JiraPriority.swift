import Foundation

/// JIRA priority levels
public enum JiraPriority: String, Sendable, Codable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}
