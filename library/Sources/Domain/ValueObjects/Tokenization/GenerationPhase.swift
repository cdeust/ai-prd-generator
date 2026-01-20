import Foundation

/// Generation phase (from PRD_GENERATION_ARCHITECTURE.md)
public enum GenerationPhase: String, Sendable, Codable, CaseIterable {
    case inputAnalysis = "Input Analysis"
    case mockupVision = "Mockup Vision"
    case codebaseAnalysis = "Codebase Analysis"
    case gapDetection = "Gap Detection"
    case selfResolution = "Self-Resolution"
    case userQuestions = "User Questions"
    case deepReasoning = "Deep Reasoning"
    case solutionExploration = "Solution Exploration"
    case codebaseValidation = "Codebase Validation"
    case sectionGeneration = "Section Generation"
    case qualityValidation = "Quality Validation"
    case refinement = "Refinement"
}
