import Foundation

/// Task types for temperature selection
public enum LLMTaskType: String, Sendable {
    case verification
    case parsing
    case extraction
    case analysis
    case summarization
    case generation
    case reasoning
    case brainstorming
    case ideation
}
