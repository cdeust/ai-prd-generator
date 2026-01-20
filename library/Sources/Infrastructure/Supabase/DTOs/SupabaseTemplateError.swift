import Foundation

/// Errors during template mapping
/// Single Responsibility: Template-specific mapping errors
public enum SupabaseTemplateError: Error, Sendable {
    case invalidSectionType(String)
    case missingRequiredField(String)
    case invalidData(String)
}
