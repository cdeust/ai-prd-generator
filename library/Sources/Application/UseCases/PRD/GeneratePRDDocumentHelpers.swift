import Foundation
import Domain

/// Extension for document creation and update helpers
extension GeneratePRDUseCase {

    func updateDocumentSections(
        documentId: UUID,
        userId: UUID,
        sections: [PRDSection],
        enrichedContext: EnrichedPRDContext?,
        request: PRDRequest,
        thinkingStrategy: String?
    ) async throws -> PRDDocument {
        let approach = buildApproachString(sectionCount: sections.count, hasEnrichedContext: enrichedContext != nil)

        let updatedDocument = PRDDocument(
            id: documentId,
            userId: userId,
            title: request.title,
            description: request.description.isEmpty ? nil : request.description,
            status: .draft,
            privacyLevel: request.privacyLevel,
            sections: sections,
            metadata: DocumentMetadata(
                author: "AI PRD Builder",
                projectName: request.title,
                aiProvider: aiProvider.providerName,
                generationApproach: approach,
                codebaseId: request.codebaseId,
                thinkingStrategy: thinkingStrategy
            )
        )

        return try await prdRepository.update(updatedDocument)
    }

    func createFinalDocument(
        documentId: UUID,
        from request: PRDRequest,
        sections: [PRDSection],
        enrichedContext: EnrichedPRDContext?,
        thinkingStrategy: String?,
        onChunk: @escaping (String) async throws -> Void
    ) async throws -> PRDDocument {
        let approach = buildApproachString(sectionCount: sections.count, hasEnrichedContext: enrichedContext != nil)
        var finalSections = sections

        if request.metadata["includeJiraInfo"] == "true" {
            let jiraSection = try await generateJiraSection(
                request: request, sections: sections, onChunk: onChunk
            )
            finalSections.append(jiraSection)
        }

        return PRDDocument(
            id: documentId,
            userId: request.userId,
            title: request.title,
            description: request.description.isEmpty ? nil : request.description,
            privacyLevel: request.privacyLevel,
            sections: finalSections,
            metadata: DocumentMetadata(
                author: "AI PRD Builder",
                projectName: request.title,
                aiProvider: aiProvider.providerName,
                generationApproach: approach,
                codebaseId: request.codebaseId,
                thinkingStrategy: thinkingStrategy
            )
        )
    }

    func mostCommonStrategy(from strategies: [ThinkingStrategy]) -> String? {
        guard !strategies.isEmpty else { return nil }

        var counts: [ThinkingStrategy: Int] = [:]
        for strategy in strategies {
            counts[strategy, default: 0] += 1
        }

        let mostCommon = counts.max(by: { $0.value < $1.value })?.key
        return mostCommon.map { ThinkingStrategyStringConverter.toString($0) }
    }

    func buildApproachString(sectionCount: Int, hasEnrichedContext: Bool) -> String {
        var approach = "Multi-pass (\(sectionCount) sections)"
        if hasEnrichedContext {
            approach += " + Enriched (RAG + Reasoning)"
        }
        return approach
    }

    func createAnalysisRequest(
        from clarificationResult: ClarificationEnrichmentResult
    ) -> PRDRequest {
        PRDRequest(
            id: clarificationResult.request.id,
            userId: clarificationResult.request.userId,
            title: clarificationResult.request.title,
            description: clarificationResult.request.description,
            requirements: clarificationResult.request.requirements,
            constraints: clarificationResult.request.constraints,
            platform: clarificationResult.request.platform,
            metadata: clarificationResult.request.metadata,
            codebaseId: clarificationResult.request.codebaseId,
            templateId: clarificationResult.request.templateId,
            mockupFileIds: clarificationResult.request.mockupFileIds,
            priority: clarificationResult.request.priority,
            targetAudience: clarificationResult.request.targetAudience,
            createdAt: clarificationResult.request.createdAt,
            phase1QuestionIds: {
                let ids = clarificationResult.answeredQuestionIds
                print("🔍 [DEBUG] Creating analysisRequest with \(ids.count) question IDs: \(ids)")
                return ids
            }()
        )
    }

    func createInitialDocument(for request: PRDRequest) -> PRDDocument {
        PRDDocument(
            userId: request.userId,
            title: request.title,
            description: request.description.isEmpty ? nil : request.description,
            status: .draft,
            privacyLevel: request.privacyLevel,
            sections: [],
            metadata: DocumentMetadata(
                author: "AI PRD Builder",
                projectName: request.title,
                aiProvider: aiProvider.providerName,
                codebaseId: request.codebaseId
            )
        )
    }

    /// Extracts human-readable summaries from mockup analysis results
    /// Used to provide context for clarification question generation
    func extractMockupSummaries(from visionResults: [MockupAnalysisResult]?) -> [String] {
        guard let results = visionResults, !results.isEmpty else { return [] }

        return results.compactMap { result -> String? in
            var parts: [String] = []

            // Include screen name and description
            if let name = result.screenName, !name.isEmpty {
                parts.append("Screen: \(name)")
            }
            if let description = result.screenDescription, !description.isEmpty {
                parts.append("Description: \(description)")
            }

            // Summarize layout type
            if let layout = result.layoutType, !layout.isEmpty {
                parts.append("Layout: \(layout)")
            }

            // Summarize UI components
            if !result.components.isEmpty {
                let componentTypes = Set(result.components.map { $0.type.rawValue })
                parts.append("UI Components: \(componentTypes.joined(separator: ", "))")

                // Include interactive components count
                let interactiveCount = result.interactiveComponents.count
                if interactiveCount > 0 {
                    parts.append("Interactive elements: \(interactiveCount)")
                }
            }

            // Summarize user flows
            if !result.flows.isEmpty {
                let flowNames = result.flows.map { $0.name }
                parts.append("User Flows: \(flowNames.joined(separator: ", "))")
            }

            // Include data requirements
            if !result.dataRequirements.isEmpty {
                let dataFields = result.dataRequirements.prefix(5).map { $0.fieldName }
                parts.append("Data fields: \(dataFields.joined(separator: ", "))")
            }

            // Include uncertainties that need clarification
            if !result.uncertainties.isEmpty {
                parts.append("Uncertainties: \(result.uncertainties.joined(separator: "; "))")
            }

            return parts.isEmpty ? nil : parts.joined(separator: "; ")
        }
    }
}
