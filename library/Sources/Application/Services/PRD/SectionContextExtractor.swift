import Foundation
import Domain

/// Extracts focused context for individual PRD sections
///
/// Selects only section-relevant context from the full request
/// to keep prompts focused and avoid unnecessary information.
///
/// **Multi-Pass Strategy:**
/// - Overview: Title + description + business goals
/// - Goals: Title + description + success metrics
/// - Requirements: Title + requirements list + constraints
/// - Technical: Stack info + architecture patterns
/// - User Stories: Personas + use cases + user flows
/// - Acceptance: Requirements + validation criteria
public actor SectionContextExtractor: Sendable {
    public init() {}

    /// Extract context relevant to specific section
    public func extractContext(
        for sectionType: SectionType,
        from request: PRDRequest
    ) -> SectionContext {
        let relevantContext = buildRelevantContext(
            for: sectionType,
            from: request
        )

        return SectionContext(
            title: request.title,
            description: request.description,
            relevantContext: relevantContext,
            sectionType: sectionType
        )
    }

    private func buildRelevantContext(
        for sectionType: SectionType,
        from request: PRDRequest
    ) -> String {
        switch sectionType {
        case .overview:
            return buildOverviewContext(request)
        case .goals:
            return buildGoalsContext(request)
        case .requirements:
            return buildRequirementsContext(request)
        case .userStories:
            return buildUserStoriesContext(request)
        case .technicalSpecification:
            return buildTechnicalContext(request)
        case .acceptanceCriteria:
            return buildAcceptanceContext(request)
        case .dataModel:
            return buildDataModelContext(request)
        case .apiSpecification:
            return buildAPIContext(request)
        case .securityConsiderations:
            return buildSecurityContext(request)
        case .performanceRequirements:
            return buildPerformanceContext(request)
        case .testing:
            return buildTestingContext(request)
        case .deployment:
            return buildDeploymentContext(request)
        case .risks:
            return buildRisksContext(request)
        case .timeline:
            return buildTimelineContext(request)
        }
    }

    // Context builders moved to SectionContextBuilders.swift extension
}
