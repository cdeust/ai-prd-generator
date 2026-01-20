import Foundation

/// Category of verification question
/// Helps organize and prioritize verification efforts
public enum VerificationCategory: String, Sendable, Codable, Equatable {
    case factualAccuracy = "factual_accuracy"
    case completeness = "completeness"
    case consistency = "consistency"
    case relevance = "relevance"
    case clarity = "clarity"
}
