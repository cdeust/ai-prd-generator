import Foundation
import Domain

/// Result of submitting an answer to clarification question
public enum ClarificationResult {
    /// Clarification complete, PRD generated
    case complete(PRDDocument)

    /// Need more clarification, continue with updated session
    case continueWithQuestions(ClarificationSession<String, Int, String>)

    /// Confidence threshold reached - user can choose to proceed or continue refining
    /// This allows infinite rounds controlled by the user
    case readyToComplete(ClarificationSession<String, Int, String>, currentCompleteness: Double)
}
