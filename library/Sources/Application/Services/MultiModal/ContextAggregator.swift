import Foundation
import Domain

/// Aggregates multi-modal analysis results into unified context
///
/// Combines:
/// - Text requirements
/// - UI components and flows
/// - Data requirements
/// - Codebase patterns
///
/// Produces enriched context for PRD generation.
public actor ContextAggregator: Sendable {
    public init() {}

    /// Aggregate multi-modal analysis into unified context
    ///
    /// - Parameter result: Multi-modal analysis result
    /// - Returns: Aggregated context ready for PRD generation
    public func aggregate(
        _ result: MultiModalAnalysisResult
    ) async throws -> AggregatedContext {
        // Extract key insights
        let uiInsights = extractUIInsights(from: result.mockupAnalysis)
        let dataInsights = extractDataInsights(from: result.mockupAnalysis)
        let codeInsights = extractCodeInsights(from: result.codebaseContext)

        // Identify cross-cutting concerns
        let concerns = identifyCrossCuttingConcerns(
            ui: uiInsights,
            data: dataInsights,
            code: codeInsights
        )

        return AggregatedContext(
            textDescription: result.textDescription,
            uiInsights: uiInsights,
            dataInsights: dataInsights,
            codeInsights: codeInsights,
            crossCuttingConcerns: concerns,
            aggregatedAt: Date()
        )
    }

    /// Extract UI insights from mockup analysis
    private func extractUIInsights(
        from mockups: [MockupAnalysisResult]
    ) -> UIInsights {
        let allComponents = mockups.flatMap { $0.components }
        let allFlows = mockups.flatMap { $0.flows }
        let allInteractions = mockups.flatMap { $0.interactions }

        return UIInsights(
            totalScreens: mockups.count,
            totalComponents: allComponents.count,
            userFlows: allFlows,
            interactions: allInteractions,
            componentBreakdown: categorizeComponents(allComponents)
        )
    }

    /// Categorize components by type
    private func categorizeComponents(
        _ components: [UIComponent]
    ) -> [String: Int] {
        Dictionary(
            grouping: components,
            by: { $0.type.rawValue }
        ).mapValues { $0.count }
    }

    /// Extract data insights from mockup analysis
    private func extractDataInsights(
        from mockups: [MockupAnalysisResult]
    ) -> DataInsights {
        let allRequirements = mockups.flatMap { $0.dataRequirements }

        let required = allRequirements.filter { $0.isRequired }
        let optional = allRequirements.filter { !$0.isRequired }

        return DataInsights(
            totalFields: allRequirements.count,
            requiredFields: required.count,
            optionalFields: optional.count,
            dataTypes: categorizeDataTypes(allRequirements),
            validationRules: extractValidationRules(allRequirements)
        )
    }

    /// Categorize data types
    private func categorizeDataTypes(
        _ requirements: [InferredDataRequirement]
    ) -> [String: Int] {
        Dictionary(
            grouping: requirements,
            by: { $0.dataType.rawValue }
        ).mapValues { $0.count }
    }

    /// Extract validation rules
    private func extractValidationRules(
        _ requirements: [InferredDataRequirement]
    ) -> [String] {
        requirements
            .flatMap { $0.validationRules }
            .reduce(into: Set<String>()) { $0.insert($1.type.rawValue) }
            .sorted()
    }

    /// Extract code insights from codebase context
    private func extractCodeInsights(
        from context: CodebaseContext?
    ) -> CodeInsights? {
        guard let context = context else { return nil }

        return CodeInsights(
            projectName: context.projectName,
            repositoryType: context.repositoryType,
            totalFiles: context.totalFiles,
            relevantFilesCount: context.uniqueFiles.count,
            totalLines: context.totalLines,
            languages: extractLanguages(from: context.relevantChunks)
        )
    }

    /// Extract programming languages
    private func extractLanguages(
        from chunks: [CodeChunk]
    ) -> Set<String> {
        Set(chunks.map { $0.language.displayName })
    }

    /// Identify cross-cutting concerns
    private func identifyCrossCuttingConcerns(
        ui: UIInsights,
        data: DataInsights,
        code: CodeInsights?
    ) -> [String] {
        var concerns: [String] = []

        // Authentication (based on UI + data)
        if ui.componentBreakdown["passwordField"] ?? 0 > 0 {
            concerns.append("Authentication")
        }

        // Data persistence (based on data requirements)
        if data.totalFields > 5 {
            concerns.append("Data Persistence")
        }

        // API integration (based on flows + code)
        if ui.userFlows.count > 3 {
            concerns.append("API Integration")
        }

        // Error handling
        if !data.validationRules.isEmpty {
            concerns.append("Error Handling & Validation")
        }

        // Networking (based on code patterns)
        if code?.languages.contains("swift") == true {
            concerns.append("Networking")
        }

        return concerns.sorted()
    }
}
