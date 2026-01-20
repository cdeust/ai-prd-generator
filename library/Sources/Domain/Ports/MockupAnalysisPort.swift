import Foundation

/// Port for analyzing mockups/wireframes
public protocol MockupAnalysisPort: Sendable {
    /// Analyze mockup and extract UI elements
    func analyzeMockup(_ mockup: Mockup) async throws -> MockupAnalysisResult

    /// Detect UI elements in image
    func detectUIElements(imageData: Data) async throws -> [UIElement]

    /// Extract text from mockup
    func extractText(from mockup: Mockup) async throws -> [String]
}
