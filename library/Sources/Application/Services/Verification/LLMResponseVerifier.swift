import Foundation
import Domain

/// Service to verify LLM responses using Chain of Verification
/// Applies multi-judge consensus to validate response accuracy against prompt
/// Following Single Responsibility: Orchestrates response verification
public actor LLMResponseVerifier {
    private let verificationService: ChainOfVerificationService?
    private let intelligenceTracker: IntelligenceTrackerService?
    private let verificationThreshold: Double

    public init(
        verificationService: ChainOfVerificationService?,
        intelligenceTracker: IntelligenceTrackerService? = nil,
        verificationThreshold: Double = 0.75
    ) {
        self.verificationService = verificationService
        self.intelligenceTracker = intelligenceTracker
        self.verificationThreshold = verificationThreshold
    }

    /// Verify an LLM response using Chain of Verification
    /// - Parameters:
    ///   - prompt: Original prompt sent to LLM
    ///   - response: Response received from LLM
    ///   - context: Additional context describing what this verification is for
    ///   - verificationType: Type of verification being performed
    /// - Returns: Verification result with pass/fail and recommendations
    /// - Throws: AIProviderError if verification fails
    public func verifyResponse(
        prompt: String,
        response: String,
        context: String? = nil,
        verificationType: VerificationType = .prdQuality
    ) async throws -> CoVVerificationResult {
        guard let verificationService = verificationService else {
            print("⚠️ [LLMResponseVerifier] No verification service available - skipping verification")
            // Return a passing result if no verification service
            return CoVVerificationResult(
                originalResponse: response,
                verificationQuestions: [],
                consensusResults: [],
                overallScore: 1.0,
                overallConfidence: 1.0,
                verified: true,
                recommendations: []
            )
        }

        let fullContext = context.map { "\($0)\n\n" } ?? ""
        let verificationRequest = "\(fullContext)Prompt: \(prompt)"

        print("🔍 [LLMResponseVerifier] Verifying LLM response...")
        print("   Type: \(verificationType)")
        print("   Threshold: \(String(format: "%.0f%%", verificationThreshold * 100))")

        let startTime = Date()
        let result = try await verificationService.verify(
            originalRequest: verificationRequest,
            response: response,
            verificationThreshold: verificationThreshold,
            verificationType: verificationType
        )
        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)

        // Track verification
        if let tracker = intelligenceTracker {
            try? await tracker.trackVerification(
                verificationType: verificationType,
                result: result,
                latencyMs: latencyMs
            )
        }

        if result.verified {
            print("✅ [LLMResponseVerifier] Verification PASSED (score: \(String(format: "%.2f", result.overallScore)))")
        } else {
            print("❌ [LLMResponseVerifier] Verification FAILED (score: \(String(format: "%.2f", result.overallScore)))")
            print("   Recommendations:")
            for rec in result.recommendations {
                print("   - \(rec)")
            }
        }

        return result
    }

    /// Verify response and return enhanced response with verification metadata
    /// - Parameters:
    ///   - prompt: Original prompt
    ///   - response: LLM response
    ///   - context: Additional context
    ///   - verificationType: Type of verification
    /// - Returns: Tuple of (response, verificationPassed, score)
    public func verifyAndEnhance(
        prompt: String,
        response: String,
        context: String? = nil,
        verificationType: VerificationType = .prdQuality
    ) async throws -> (response: String, verified: Bool, score: Double) {
        let result = try await verifyResponse(
            prompt: prompt,
            response: response,
            context: context,
            verificationType: verificationType
        )

        var enhancedResponse = response

        // Add verification metadata for failed verifications
        if !result.verified {
            enhancedResponse += """


            <!-- Verification Metadata -->
            <!-- Score: \(String(format: "%.0f%%", result.overallScore * 100)) -->
            <!-- Confidence: \(String(format: "%.0f%%", result.overallConfidence * 100)) -->
            <!-- Recommendations: \(result.recommendations.joined(separator: "; ")) -->
            """
        }

        return (enhancedResponse, result.verified, result.overallScore)
    }
}

// MARK: - IntelligenceTrackerService Extension
extension IntelligenceTrackerService {
    func trackVerification(
        verificationType: VerificationType,
        result: CoVVerificationResult,
        latencyMs: Int
    ) async throws {
        print("📊 [Intelligence] Tracked \(verificationType) verification: verified=\(result.verified), score=\(String(format: "%.2f", result.overallScore)), latency=\(latencyMs)ms")
        // Implementation can be extended for persistence
    }
}
