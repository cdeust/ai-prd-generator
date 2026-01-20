@preconcurrency import Foundation

/// Public mockup input
/// Public DTO for mockup data
public struct MockupInput: Sendable {
    public let url: URL?
    public let data: Data?
    public let filename: String

    public init(url: URL? = nil, data: Data? = nil, filename: String) {
        self.url = url
        self.data = data
        self.filename = filename
    }
}
