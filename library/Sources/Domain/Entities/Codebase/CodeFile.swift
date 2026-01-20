import Foundation

/// Code file entity
/// Following Single Responsibility Principle - represents single code file
public struct CodeFile: Identifiable, Sendable {
    public let id: UUID
    public let codebaseId: UUID
    public let projectId: UUID
    public let filePath: String
    public let fileHash: String
    public let fileSize: Int
    public let language: ProgrammingLanguage?
    public let isParsed: Bool
    public let parseError: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        codebaseId: UUID,
        projectId: UUID,
        filePath: String,
        fileHash: String,
        fileSize: Int,
        language: ProgrammingLanguage? = nil,
        isParsed: Bool = false,
        parseError: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.codebaseId = codebaseId
        self.projectId = projectId
        self.filePath = filePath
        self.fileHash = fileHash
        self.fileSize = fileSize
        self.language = language
        self.isParsed = isParsed
        self.parseError = parseError
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
