import Foundation

/// Thinking mode for PRD generation
/// Following Single Responsibility Principle - represents thinking depth
public enum ThinkingMode: String, Sendable, Codable {
    case fast           // Quick generation, minimal thinking
    case standard       // Normal thinking depth
    case deep           // --think flag (4K tokens)
    case veryDeep       // --think-hard (10K tokens)
    case ultraDeep      // --ultrathink (32K tokens)

    public var tokenBudget: Int {
        switch self {
        case .fast: return 1000
        case .standard: return 2000
        case .deep: return 4000
        case .veryDeep: return 10000
        case .ultraDeep: return 32000
        }
    }

    public var displayName: String {
        switch self {
        case .fast: return "Fast"
        case .standard: return "Standard"
        case .deep: return "Deep Thinking"
        case .veryDeep: return "Very Deep Thinking"
        case .ultraDeep: return "Ultra Deep Thinking"
        }
    }
}
