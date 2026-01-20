import Foundation

/// Supabase PRD Request Record
/// Maps to prd_requests table schema
/// Backend compatibility layer (ONLY exception per Rule 8)
public struct SupabasePRDRequestRecord: Codable {
    let id: UUID
    let title: String
    let description: String
    let priority: String
    let status: String
    let requesterId: String
    let requesterName: String?
    let requesterEmail: String?
    let mockupSources: [[String: String]]?
    let generationOptions: [String: String]?
    let metadata: [String: String]?
    let createdAt: Date
    let updatedAt: Date
    let completedAt: Date?
    let preferredProvider: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case priority
        case status
        case requesterId = "requester_id"
        case requesterName = "requester_name"
        case requesterEmail = "requester_email"
        case mockupSources = "mockup_sources"
        case generationOptions = "generation_options"
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case preferredProvider = "preferred_provider"
    }
}
