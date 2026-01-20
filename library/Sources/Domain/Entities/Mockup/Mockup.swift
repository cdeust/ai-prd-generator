import Foundation

/// Mockup/wireframe entity for visual requirements
/// Following Single Responsibility Principle - represents mockup container
public struct Mockup: Identifiable, Sendable, Codable {
    public let id: UUID
    public let prdDocumentId: UUID?
    public let name: String
    public let description: String?
    public let type: MockupType
    public let source: MockupSource
    public let fileUrl: String
    public let fileSize: Int?
    public let width: Int?
    public let height: Int?
    public let extractedElements: [UIElement]
    public let annotations: [Annotation]
    public let analysisResult: MockupAnalysisResult?
    public let orderIndex: Int
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        prdDocumentId: UUID? = nil,
        name: String,
        description: String? = nil,
        type: MockupType,
        source: MockupSource,
        fileUrl: String,
        fileSize: Int? = nil,
        width: Int? = nil,
        height: Int? = nil,
        extractedElements: [UIElement] = [],
        annotations: [Annotation] = [],
        analysisResult: MockupAnalysisResult? = nil,
        orderIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.prdDocumentId = prdDocumentId
        self.name = name
        self.description = description
        self.type = type
        self.source = source
        self.fileUrl = fileUrl
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.extractedElements = extractedElements
        self.annotations = annotations
        self.analysisResult = analysisResult
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
