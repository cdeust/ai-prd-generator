import Foundation

/// Visual context from image analysis
public struct VisualContext: Sendable {
    public let imageIndex: Int
    public let imageUrl: String
    public let description: String
    public let elements: [String]

    public init(imageIndex: Int, imageUrl: String, description: String, elements: [String]) {
        self.imageIndex = imageIndex
        self.imageUrl = imageUrl
        self.description = description
        self.elements = elements
    }
}
