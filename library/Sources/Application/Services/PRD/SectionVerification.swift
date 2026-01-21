import Foundation
import Domain

/// Handles verification of PRD sections for consistency and quality
/// Uses Chain of Verification with multi-LLM consensus
/// Following Single Responsibility: Only verifies section content
struct SectionVerification: Sendable {
    private let verificationService: ChainOfVerificationService?

    init(verificationService: ChainOfVerificationService?) {
        self.verificationService = verificationService
    }

    /// Verify section content for consistency, accuracy, and quality
    func verifySection(
        content: String,
        sectionType: SectionType,
        request: PRDRequest
    ) async throws -> String {
        guard let verificationService = verificationService else {
            // No verification service - return original content
            return content
        }

        print("🔍 Verifying \(sectionType.displayName) section...")

        let originalRequest = buildVerificationRequest(sectionType: sectionType, request: request)

        do {
            let result = try await verificationService.verify(
                originalRequest: originalRequest,
                response: content,
                verificationThreshold: 0.75
            )

            logVerificationResult(result: result, sectionType: sectionType)
            return content
        } catch {
            print("⚠️  Verification failed for \(sectionType.displayName): \(error)")
            return content
        }
    }

    private func logVerificationResult(
        result: CoVVerificationResult,
        sectionType: SectionType
    ) {
        if result.verified {
            print("✅ \(sectionType.displayName) passed verification (score: \(String(format: "%.2f", result.overallScore)))")
        } else {
            print("⚠️  \(sectionType.displayName) verification score: \(String(format: "%.2f", result.overallScore))")
            for recommendation in result.recommendations {
                print("   • \(recommendation)")
            }
        }
    }

    private func buildVerificationRequest(
        sectionType: SectionType,
        request: PRDRequest
    ) -> String {
        """
        Create a \(sectionType.displayName) section for this PRD:

        Title: \(request.title)
        Description: \(request.description)

        Requirements:
        \(request.requirements.map { "- \($0)" }.joined(separator: "\n"))

        The section must be consistent with the requirements and provide accurate, complete information.
        """
    }
}
