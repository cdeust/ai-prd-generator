import Foundation
import Domain

/// Generates section-specific clarification questions during PRD generation
public struct SectionClarificationService: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Generate clarification questions specific to a section type
    public func generateQuestionsForSection(
        _ sectionType: SectionType,
        request: PRDRequest,
        previousSections: [PRDSection]
    ) async throws -> [ClarificationQuestion<String, Int, String>] {
        switch sectionType {
        case .overview:
            return generateOverviewQuestions(request)
        case .goals:
            return generateGoalsQuestions(request)
        case .requirements:
            return generateRequirementsQuestions(request)
        case .userStories:
            return generateUserStoriesQuestions(request, previousSections: previousSections)
        case .technicalSpecification:
            return generateTechnicalQuestions(request, previousSections: previousSections)
        case .acceptanceCriteria:
            return generateAcceptanceCriteriaQuestions(request, previousSections: previousSections)
        default:
            return []
        }
    }

    private func generateOverviewQuestions(
        _ request: PRDRequest
    ) -> [ClarificationQuestion<String, Int, String>] {
        var questions: [ClarificationQuestion<String, Int, String>] = []

        if !hasTargetAudience(request.description) {
            questions.append(ClarificationQuestion(
                category: QuestionCategory("business"),
                question: "Who is the primary target audience for this feature?",
                rationale: "Understanding users helps define appropriate scope and UX",
                examples: ["B2B enterprise users", "Consumer mobile users", "Internal team members"],
                priority: QuestionPriority(10),
                detectedGap: GapType("missing_audience")
            ))
        }

        if !hasBusinessContext(request.description) {
            questions.append(ClarificationQuestion(
                category: QuestionCategory("business"),
                question: "What business problem does this feature solve?",
                rationale: "Clear business context ensures the PRD aligns with company goals",
                examples: ["Reduce support tickets", "Increase conversion rate", "Improve user retention"],
                priority: QuestionPriority(9),
                detectedGap: GapType("missing_business_context")
            ))
        }

        return questions
    }

    private func generateGoalsQuestions(
        _ request: PRDRequest
    ) -> [ClarificationQuestion<String, Int, String>] {
        var questions: [ClarificationQuestion<String, Int, String>] = []

        if !hasSuccessMetrics(request.description) {
            questions.append(ClarificationQuestion(
                category: QuestionCategory("metrics"),
                question: "What metrics will define success for this feature?",
                rationale: "Measurable goals ensure alignment and enable tracking progress",
                examples: ["20% reduction in page load time", "50% increase in feature adoption"],
                priority: QuestionPriority(10),
                detectedGap: GapType("missing_success_metrics")
            ))
        }

        if !hasTimeline(request.description) {
            questions.append(ClarificationQuestion(
                category: QuestionCategory("planning"),
                question: "What is the expected timeline or release target?",
                rationale: "Timeline affects scope decisions and prioritization",
                examples: ["MVP in 4 weeks", "Q2 release", "Phased rollout over 3 months"],
                priority: QuestionPriority(8),
                detectedGap: GapType("missing_timeline")
            ))
        }

        return questions
    }

    private func generateRequirementsQuestions(
        _ request: PRDRequest
    ) -> [ClarificationQuestion<String, Int, String>] {
        var questions: [ClarificationQuestion<String, Int, String>] = []

        if !hasSecurityRequirements(request.description) {
            questions.append(ClarificationQuestion(
                category: QuestionCategory("security"),
                question: "Are there specific security or compliance requirements?",
                rationale: "Security requirements affect architecture and implementation",
                examples: ["GDPR compliance", "SOC 2", "End-to-end encryption", "No special requirements"],
                priority: QuestionPriority(9),
                detectedGap: GapType("missing_security_requirements")
            ))
        }

        if !hasPerformanceRequirements(request.description) {
            questions.append(ClarificationQuestion(
                category: QuestionCategory("performance"),
                question: "What are the performance expectations?",
                rationale: "Performance targets guide technical decisions",
                examples: ["Sub-second response time", "Support 10K concurrent users", "99.9% uptime"],
                priority: QuestionPriority(8),
                detectedGap: GapType("missing_performance_requirements")
            ))
        }

        return questions
    }

    private func generateUserStoriesQuestions(
        _ request: PRDRequest,
        previousSections: [PRDSection]
    ) -> [ClarificationQuestion<String, Int, String>] {
        var questions: [ClarificationQuestion<String, Int, String>] = []

        if !hasUserRoles(request.description, previousSections: previousSections) {
            questions.append(ClarificationQuestion(
                category: QuestionCategory("users"),
                question: "What user roles or personas will interact with this feature?",
                rationale: "Different roles may have different needs and permissions",
                examples: ["Admin, Editor, Viewer", "Free user, Premium user", "Customer, Support agent"],
                priority: QuestionPriority(10),
                detectedGap: GapType("missing_user_roles")
            ))
        }

        return questions
    }

    private func generateTechnicalQuestions(
        _ request: PRDRequest,
        previousSections: [PRDSection]
    ) -> [ClarificationQuestion<String, Int, String>] {
        var questions: [ClarificationQuestion<String, Int, String>] = []

        if !hasIntegrationDetails(request.description, previousSections: previousSections) {
            questions.append(ClarificationQuestion(
                category: QuestionCategory("technical"),
                question: "Are there existing systems or APIs this feature needs to integrate with?",
                rationale: "Integrations affect technical architecture and complexity",
                examples: ["Payment gateway (Stripe)", "Authentication (Auth0)", "No external integrations"],
                priority: QuestionPriority(9),
                detectedGap: GapType("missing_integrations")
            ))
        }

        if !hasDataMigration(request.description, previousSections: previousSections) {
            questions.append(ClarificationQuestion(
                category: QuestionCategory("technical"),
                question: "Is data migration or backward compatibility required?",
                rationale: "Migration needs affect implementation approach and timeline",
                examples: ["Migrate from legacy system", "Support both old and new API", "New system, no migration"],
                priority: QuestionPriority(8),
                detectedGap: GapType("missing_migration_info")
            ))
        }

        return questions
    }

    private func generateAcceptanceCriteriaQuestions(
        _ request: PRDRequest,
        previousSections: [PRDSection]
    ) -> [ClarificationQuestion<String, Int, String>] {
        var questions: [ClarificationQuestion<String, Int, String>] = []

        if !hasTestingApproach(request.description, previousSections: previousSections) {
            questions.append(ClarificationQuestion(
                category: QuestionCategory("testing"),
                question: "What testing approach is expected?",
                rationale: "Testing strategy affects development workflow and quality",
                examples: ["Unit tests only", "Full E2E testing", "Manual QA process"],
                priority: QuestionPriority(8),
                detectedGap: GapType("missing_testing_approach")
            ))
        }

        return questions
    }

    // MARK: - Detection Helpers

    private func hasTargetAudience(_ text: String) -> Bool {
        let keywords = ["target audience", "users", "customers", "personas", "demographic"]
        return keywords.contains { text.lowercased().contains($0) }
    }

    private func hasBusinessContext(_ text: String) -> Bool {
        let keywords = ["business", "revenue", "conversion", "retention", "ROI", "KPI"]
        return keywords.contains { text.lowercased().contains($0) }
    }

    private func hasSuccessMetrics(_ text: String) -> Bool {
        let keywords = ["metrics", "success criteria", "KPI", "measure", "goal", "%", "increase", "decrease"]
        return keywords.contains { text.lowercased().contains($0) }
    }

    private func hasTimeline(_ text: String) -> Bool {
        let keywords = ["deadline", "timeline", "release", "launch", "Q1", "Q2", "Q3", "Q4", "weeks", "months"]
        return keywords.contains { text.lowercased().contains($0) }
    }

    private func hasSecurityRequirements(_ text: String) -> Bool {
        let keywords = ["security", "GDPR", "compliance", "encryption", "authentication", "authorization"]
        return keywords.contains { text.lowercased().contains($0) }
    }

    private func hasPerformanceRequirements(_ text: String) -> Bool {
        let keywords = ["performance", "latency", "response time", "concurrent", "scalability", "uptime"]
        return keywords.contains { text.lowercased().contains($0) }
    }

    private func hasUserRoles(_ text: String, previousSections: [PRDSection]) -> Bool {
        let allContent = text + previousSections.map { $0.content }.joined()
        let keywords = ["admin", "user role", "persona", "permission", "role-based"]
        return keywords.contains { allContent.lowercased().contains($0) }
    }

    private func hasIntegrationDetails(_ text: String, previousSections: [PRDSection]) -> Bool {
        let allContent = text + previousSections.map { $0.content }.joined()
        let keywords = ["integration", "API", "third-party", "external service", "webhook"]
        return keywords.contains { allContent.lowercased().contains($0) }
    }

    private func hasDataMigration(_ text: String, previousSections: [PRDSection]) -> Bool {
        let allContent = text + previousSections.map { $0.content }.joined()
        let keywords = ["migration", "backward compatible", "legacy", "migrate", "existing data"]
        return keywords.contains { allContent.lowercased().contains($0) }
    }

    private func hasTestingApproach(_ text: String, previousSections: [PRDSection]) -> Bool {
        let allContent = text + previousSections.map { $0.content }.joined()
        let keywords = ["test", "QA", "unit test", "e2e", "acceptance test", "testing"]
        return keywords.contains { allContent.lowercased().contains($0) }
    }
}
