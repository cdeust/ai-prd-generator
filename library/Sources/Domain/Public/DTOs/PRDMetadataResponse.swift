import Foundation

/// Public PRD metadata
/// Public DTO for PRD metadata
public struct PRDMetadataResponse: Sendable {
    public let createdAt: Date
    public let version: String
    public let taskType: String?

    public init(createdAt: Date, version: String, taskType: String? = nil) {
        self.createdAt = createdAt
        self.version = version
        self.taskType = taskType
    }
}
