import Foundation

/// Purpose of an LLM interaction
/// Categorizes why an AI call was made
public enum InteractionPurpose: String, Sendable, Codable, CaseIterable {
    case requirementAnalysis = "requirement_analysis"
    case clarification = "clarification"
    case sectionGeneration = "section_generation"
    case jiraTicket = "jira_ticket"
    case mockupAnalysis = "mockup_analysis"
    case ragQuery = "rag_query"
    case strategySelection = "strategy_selection"
    case refinement = "refinement"
    case validation = "validation"
}
