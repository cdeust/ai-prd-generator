import Foundation

/// Gemini chunk data structure
struct GeminiResponseChunk: Codable, Sendable {
    let candidates: [Candidate]?

    struct Candidate: Codable, Sendable {
        let content: Content?

        struct Content: Codable, Sendable {
            let parts: [Part]?

            struct Part: Codable, Sendable {
                let text: String?
            }
        }
    }
}

