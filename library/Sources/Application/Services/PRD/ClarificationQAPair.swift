import Foundation

/// Q&A pair for tracking what's already been clarified
/// Used to pass both question and answer to prompt builder so LLM knows what's resolved
struct ClarificationQAPair: Sendable {
    let question: String
    let answer: String
}
