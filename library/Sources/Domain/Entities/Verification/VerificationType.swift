import Foundation

/// Type of verification being performed
public enum VerificationType: String, Sendable, Codable {
    case prdQuality = "prd_quality"
    case questionRelevance = "question_relevance"
    case technicalFeasibility = "technical_feasibility"
    case completeness = "completeness"
    case consistency = "consistency"
}
