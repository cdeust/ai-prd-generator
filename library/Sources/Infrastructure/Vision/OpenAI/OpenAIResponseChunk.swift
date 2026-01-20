import Foundation

/// OpenAI chunk data structure
struct OpenAIResponseChunk: Codable, Sendable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]?

    struct Choice: Codable, Sendable {
        let delta: Delta?
        let index: Int?

        struct Delta: Codable, Sendable {
            let content: String?
        }
    }
}

