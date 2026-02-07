import AIPRDSharedUtilities
import Foundation

/// Update struct for file parse status
internal struct PGFileParseUpdate: Encodable {
    let isParsed: Bool
    let parseError: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case isParsed = "is_parsed"
        case parseError = "parse_error"
        case updatedAt = "updated_at"
    }
}
