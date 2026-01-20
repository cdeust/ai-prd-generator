import Foundation

/// Result of Chain of Verification (CoV) process
/// Combines verification questions, judge evaluations, and consensus
/// Following Single Responsibility: Represents complete verification outcome
public struct CoVVerificationResult: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public let originalResponse: String
    public let verificationQuestions: [VerificationQuestion]
    public let consensusResults: [JudgmentConsensus]
    public let overallScore: Double
    public let overallConfidence: Double
    public let verified: Bool
    public let recommendations: [String]
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        originalResponse: String,
        verificationQuestions: [VerificationQuestion],
        consensusResults: [JudgmentConsensus],
        overallScore: Double,
        overallConfidence: Double,
        verified: Bool,
        recommendations: [String],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.originalResponse = originalResponse
        self.verificationQuestions = verificationQuestions
        self.consensusResults = consensusResults
        self.overallScore = overallScore
        self.overallConfidence = overallConfidence
        self.verified = verified
        self.recommendations = recommendations
        self.timestamp = timestamp
    }

    /// Whether verification shows strong confidence
    /// Strong confidence = high score + high confidence + verified
    public var hasStrongConfidence: Bool {
        verified && overallScore > 0.8 && overallConfidence > 0.8
    }

    /// Average agreement level across all consensus results
    /// Used to assess overall judge agreement
    public var averageAgreementLevel: AgreementLevel {
        guard !consensusResults.isEmpty else { return .low }

        let highCount = consensusResults.filter { $0.agreementLevel == .high }.count
        let mediumCount = consensusResults.filter { $0.agreementLevel == .medium }.count

        let highRatio = Double(highCount) / Double(consensusResults.count)
        let mediumRatio = Double(mediumCount) / Double(consensusResults.count)

        if highRatio > 0.7 {
            return .high
        } else if highRatio + mediumRatio > 0.7 {
            return .medium
        } else {
            return .low
        }
    }

    /// Number of judges that participated
    /// Derived from individual scores in consensus results
    public var judgeCount: Int {
        guard let firstConsensus = consensusResults.first else { return 0 }
        return firstConsensus.individualScores.count
    }
}
