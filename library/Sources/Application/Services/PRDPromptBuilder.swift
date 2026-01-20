import Foundation
import Domain

/// Builds sophisticated prompts for PRD generation
/// Following Single Responsibility Principle - ONE job: construct prompts
/// Extracted from GeneratePRDUseCase for reusability and testability
public struct PRDPromptBuilder: Sendable {
    private let promptService: PromptEngineeringService?
    private let tokenizer: TokenizerPort?
    private let compressor: AppleIntelligenceContextCompressor?
    private let contextInjector: EnrichedContextInjector

    public init(
        promptService: PromptEngineeringService?,
        tokenizer: TokenizerPort? = nil,
        compressor: AppleIntelligenceContextCompressor? = nil
    ) {
        self.promptService = promptService
        self.tokenizer = tokenizer
        self.compressor = compressor
        self.contextInjector = EnrichedContextInjector()
    }

    /// Build prompt from request using base or sophisticated strategy
    /// NO compression - send prompts directly like old ai-prd-builder
    public func buildPrompt(
        from request: PRDRequest,
        using template: PRDTemplate?,
        budget: PromptBudget
    ) async -> String {
        // Build prompt without compression
        if let template = template {
            return buildTemplateBasedPrompt(request: request, template: template)
        } else {
            return await buildBasePrompt(from: request)
        }
    }

    /// Compress prompt to fit within budget
    private func compressPrompt(
        _ prompt: String,
        budget: PromptBudget
    ) async throws -> String {
        guard let tokenizer = tokenizer else { return prompt }
        guard let compressor = compressor else { return prompt }

        let tokenCount = try await tokenizer.countTokens(in: prompt)
        guard tokenCount > budget.promptBudget else { return prompt }

        let compressed = try await compressor.compressForAppleIntelligence(
            prompt,
            targetTokens: budget.promptBudget
        )

        return compressed.compressedText
    }

    /// Build focused prompt for a single section using professional templates
    /// with section-specific enriched context (multi-pass intelligence)
    public func buildSectionPrompt(
        for sectionType: SectionType,
        sectionContext: SectionContext,
        enrichedContext: EnrichedPRDContext? = nil,
        contextBuilder: EnrichedContextBuilder?
    ) async -> String {
        // Build base prompt using PromptEngineeringService templates
        let basePrompt: String
        if let promptService = promptService {
            let promptContext = PromptContext(
                title: sectionContext.title,
                description: sectionContext.description,
                requirements: [], // Extracted in sectionContext.relevantContext
                sectionType: sectionType
            )

            if let professionalPrompt = try? await promptService.generateSectionPrompt(
                for: sectionType,
                context: promptContext
            ) {
                basePrompt = professionalPrompt
            } else {
                basePrompt = await promptService.generateFallbackPrompt(for: sectionType, context: promptContext)
            }
        } else {
            // No PromptEngineeringService - use simple fallback
            basePrompt = buildSimpleFallback(sectionType: sectionType, sectionContext: sectionContext)
        }

        // Extract section-specific enriched context (multi-pass approach)
        let sectionEnrichedContext: String
        if let enriched = enrichedContext, let builder = contextBuilder {
            // Get FULL relevant intelligence for THIS section (not truncated)
            sectionEnrichedContext = await builder.buildSectionContext(
                for: sectionType,
                from: enriched
            )
        } else {
            sectionEnrichedContext = ""
        }

        // Inject section-specific intelligence
        return contextInjector.injectContext(
            into: basePrompt,
            sectionContext: sectionContext,
            enrichedContext: sectionEnrichedContext
        )
    }

    /// Simple fallback when PromptEngineeringService unavailable
    private func buildSimpleFallback(
        sectionType: SectionType,
        sectionContext: SectionContext
    ) -> String {
        """
        <instruction>
        You are a senior product manager writing a Product Requirements Document.
        Generate the \(sectionType.displayName) section.
        </instruction>

        <input>
        Title: \(sectionContext.title)
        Description: \(sectionContext.description)
        </input>
        """
    }

    /// Enrich prompt with codebase context
    public func enrichWithContext(_ prompt: String, context: String) -> String {
        """
        <codebase_context>
        The following code from the existing codebase is relevant to this PRD:
        \(context)

        When writing the PRD, take into account the existing codebase structure and patterns shown above.
        Ensure consistency with existing code architecture.
        </codebase_context>

        \(prompt)
        """
    }

    // MARK: - Private Helpers

    private func buildBasePrompt(from request: PRDRequest) async -> String {
        // If PromptEngineeringService is available, use sophisticated prompts
        if let promptService = promptService {
            return await buildSophisticatedPrompt(from: request, using: promptService)
        }

        // Fallback to basic prompt
        return BasePromptTemplate.build(
            title: request.title,
            description: request.description,
            requirements: request.requirements
        )
    }

    private func buildSophisticatedPrompt(
        from request: PRDRequest,
        using service: PromptEngineeringService
    ) async -> String {
        let sectionTypes: [SectionType] = [
            .overview, .goals, .requirements,
            .userStories, .technicalSpecification, .acceptanceCriteria
        ]

        let requirementStrings = request.requirements.map { $0.description }
        let header = buildPromptHeader(
            title: request.title,
            description: request.description,
            requirements: requirementStrings
        )
        let sectionInstructions = await buildSectionInstructions(
            sectionTypes: sectionTypes,
            title: request.title,
            description: request.description,
            requirements: requirementStrings,
            service: service
        )
        let footer = buildPromptFooter()

        return header + sectionInstructions + footer
    }

    private func buildPromptHeader(
        title: String,
        description: String,
        requirements: [String]
    ) -> String {
        let reqText = requirements.isEmpty ? "None specified" : requirements.joined(separator: ", ")
        return """
        <instruction>
        You are a senior product manager writing a comprehensive Product Requirements Document (PRD).
        Generate a complete PRD with the following sections, following the specific instructions for each section.
        </instruction>
        <input>
        Title: \(title)
        Description: \(description)
        Requirements: \(reqText)
        </input>
        <task>Generate PRD Sections</task>
        """
    }

    private func buildSectionInstructions(
        sectionTypes: [SectionType],
        title: String,
        description: String,
        requirements: [String],
        service: PromptEngineeringService
    ) async -> String {
        var instructions = ""

        for sectionType in sectionTypes {
            let context = PromptContext(
                title: title,
                description: description,
                requirements: requirements,
                sectionType: sectionType
            )

            let sectionPrompt: String
            if let prompt = try? await service.generateSectionPrompt(for: sectionType, context: context) {
                sectionPrompt = prompt
            } else {
                sectionPrompt = await service.generateFallbackPrompt(for: sectionType, context: context)
            }

            instructions += """

            <section name="\(sectionType.rawValue)">
            \(sectionPrompt)
            </section>

            """
        }

        return instructions
    }

    private func buildPromptFooter() -> String {
        return """
        <requirements>
        - Generate ALL sections listed above
        - Follow the specific instructions for each section
        - Use Markdown formatting
        - Be specific and avoid generic content
        - Total length: 2000-3000 words
        </requirements>
        """
    }

    private func buildTemplateBasedPrompt(
        request: PRDRequest,
        template: PRDTemplate
    ) -> String {
        let sections = template.orderedSections
        let sectionList = sections.map { config in
            let required = config.isRequired ? " (Required)" : ""
            return "- \(config.sectionType.displayName)\(required)"
        }.joined(separator: "\n")

        return """
        <instruction>
        Generate a Product Requirements Document using the '\(template.name)' template.
        </instruction>

        <input>
        Project Title: \(request.title)
        Project Description: \(request.description)
        Requirements: \(formatRequirements(request.requirements))
        </input>

        <template_structure>
        Create sections in this exact order:
        \(sectionList)
        </template_structure>

        <requirements>
        - Follow the section order specified above
        - Include all required sections
        - Format output in Markdown
        - Use appropriate detail for each section
        </requirements>
        """
    }

    private func formatRequirements(_ requirements: [Requirement]) -> String {
        guard !requirements.isEmpty else {
            return "No specific requirements provided."
        }

        return requirements
            .map { "- \($0.description) (Priority: \($0.priority.displayName))" }
            .joined(separator: "\n")
    }

}
