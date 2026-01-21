import Foundation

/// Intent derived from user message in conversational session
enum MessageIntent {
    case newPRD(title: String, description: String)
    case refinePRD(instructions: String)
}
