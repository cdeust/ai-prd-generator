import Foundation

/// Port for analyzing UI mockups using vision AI models.
///
/// Supports provider-agnostic mockup analysis for extracting:
/// - UI components and their properties
/// - User flows and navigation patterns
/// - Interactions and feedback mechanisms
/// - Inferred data requirements from forms
///
/// Implementations can use:
/// - Claude Vision (Anthropic)
/// - GPT-4V (OpenAI)
/// - Gemini Vision (Google)
/// - Apple Vision Framework
public protocol VisionAnalysisPort: Sendable {
    /// Analyze a single mockup image
    ///
    /// - Parameters:
    ///   - imageData: Binary image data (PNG or JPEG)
    ///   - prompt: Optional guidance for analysis focus
    /// - Returns: Analysis result with extracted components, flows, and data requirements
    /// - Throws: MockupAnalysisError if analysis fails
    func analyzeMockup(
        imageData: Data,
        prompt: String?
    ) async throws -> MockupAnalysisResult

    /// Analyze multiple mockup images (batch processing)
    ///
    /// - Parameters:
    ///   - images: Array of mockup images to analyze
    /// - Returns: Array of analysis results (one per image)
    /// - Throws: MockupAnalysisError if batch analysis fails
    func analyzeMultipleMockups(
        images: [MockupImage]
    ) async throws -> [MockupAnalysisResult]

    /// Extract user flows across multiple screens
    ///
    /// Analyzes navigation patterns between screens by examining:
    /// - Button/link interactions
    /// - Navigation components (back buttons, tab bars)
    /// - Modal presentations and dismissals
    ///
    /// - Parameters:
    ///   - screens: Pre-analyzed mockup results to connect
    /// - Returns: Array of identified user flows
    /// - Throws: MockupAnalysisError if flow extraction fails
    func extractUserFlows(
        from screens: [MockupAnalysisResult]
    ) async throws -> [UserFlow]

    /// Provider name (e.g., "Claude Vision", "GPT-4V")
    var providerName: String { get }

    /// Model name (e.g., "claude-3-5-sonnet-20241022")
    var modelName: String { get }
}
