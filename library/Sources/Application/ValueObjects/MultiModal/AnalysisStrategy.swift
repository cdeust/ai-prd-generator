import Foundation

/// Strategy for input analysis based on available data
public enum AnalysisStrategy: String, Sendable, Equatable, Codable {
    /// Analyze all inputs (text + mockups + codebase)
    case comprehensive

    /// Focus on mockup analysis with text context
    case mockupFocused

    /// Focus on codebase analysis with text context
    case codebaseFocused

    /// Text description only
    case textOnly

    /// Human-readable description
    public var description: String {
        switch self {
        case .comprehensive:
            return "Comprehensive multi-modal analysis"
        case .mockupFocused:
            return "Mockup-focused visual analysis"
        case .codebaseFocused:
            return "Codebase-focused technical analysis"
        case .textOnly:
            return "Text-only requirement analysis"
        }
    }

    /// Relative analysis depth
    public var depth: Int {
        switch self {
        case .comprehensive: return 3
        case .mockupFocused, .codebaseFocused: return 2
        case .textOnly: return 1
        }
    }
}
