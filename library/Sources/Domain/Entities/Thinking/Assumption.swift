import Foundation

/// Assumption made during reasoning
/// Following Single Responsibility: Represents assumption entity only
public struct Assumption: Identifiable, Sendable, Codable {
    public let id: UUID
    public let description: String
    public let confidence: Double
    public let requiresValidation: Bool
    public let validationMethod: String?

    public init(
        id: UUID = UUID(),
        description: String,
        confidence: Double,
        requiresValidation: Bool,
        validationMethod: String? = nil
    ) {
        self.id = id
        self.description = description
        self.confidence = confidence
        self.requiresValidation = requiresValidation
        self.validationMethod = validationMethod
    }
}
