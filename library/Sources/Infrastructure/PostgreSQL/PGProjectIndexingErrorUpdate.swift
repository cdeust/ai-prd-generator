import AIPRDSharedUtilities
import Foundation

/// Update struct for project indexing error
internal struct PGProjectIndexingErrorUpdate: Encodable {
    let indexingStatus: String
    let indexingError: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case indexingStatus = "indexing_status"
        case indexingError = "indexing_error"
        case updatedAt = "updated_at"
    }
}
