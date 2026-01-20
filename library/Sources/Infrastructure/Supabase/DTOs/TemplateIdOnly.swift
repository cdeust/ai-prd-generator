import Foundation

/// Minimal struct for existence checks - only decodes id field
/// Used by SupabasePRDTemplateRepository.existsByName to avoid decoding issues
struct TemplateIdOnly: Decodable {
    let id: UUID
}
