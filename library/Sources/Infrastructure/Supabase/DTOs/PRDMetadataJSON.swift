import Foundation

/// JSONB structure for PRD metadata
/// Maps to metadata_json column in prd_documents table
public struct PRDMetadataJSON: Codable, Sendable {
    let author: String?
    let projectName: String?
    let aiProvider: String?
    let generationApproach: String?
    let sections: [[String: String]]?
}
