import Foundation

/// File parse status update DTO
/// Backend compatibility layer (ONLY exception per Rule 8)
/// Single Responsibility: Update file parsing status in database
struct FileParseUpdate: Encodable {
    let isParsed: Bool
    let parseError: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case isParsed = "is_parsed"
        case parseError = "parse_error"
        case updatedAt = "updated_at"
    }
}
