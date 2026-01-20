import Foundation
import Domain

/// Result of submitting an answer to clarification question
public enum ClarificationResult {
    /// Clarification complete, PRD generated
    case complete(PRDDocument)

    /// Need more clarification, continue with updated session
    case continueWithQuestions(ClarificationSession<String, Int, String>)
}
