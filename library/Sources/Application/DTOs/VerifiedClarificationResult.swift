import Foundation
import Domain

/// Result of verified clarification with optional verification details
/// Returned by VerifiedClarificationOrchestratorUseCase
/// Following Single Responsibility: Represents verification outcome
public enum VerifiedClarificationResult {
    case complete(PRDDocument, verificationResult: CoVVerificationResult?)
    case continueWithQuestions(ClarificationSession<String, Int, String>)
    case readyToComplete(ClarificationSession<String, Int, String>, currentCompleteness: Double)
}
