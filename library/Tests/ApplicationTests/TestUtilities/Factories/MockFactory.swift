import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation
@testable import Domain
@testable import Application

/// Central factory for creating test mocks and fixtures
/// Simplifies test setup and ensures consistency
public enum MockFactory {
    // MARK: - Mock Providers

    public static func createAIProvider(
        providerName: String = "MockProvider",
        modelName: String = "mock-model-1",
        responseMode: MockAIProvider.ResponseMode = .success("Mock response")
    ) -> MockAIProvider {
        MockAIProvider(
            providerName: providerName,
            modelName: modelName,
            responseMode: responseMode
        )
    }

    public static func createEmbeddingGenerator(
        dimension: Int = 384,
        modelName: String = "mock-embedder"
    ) -> MockPRDEmbeddingGenerator {
        MockPRDEmbeddingGenerator(
            dimension: dimension,
            modelName: modelName
        )
    }

    // MARK: - Mock Repositories

    public static func createPRDRepository() -> MockPRDRepository {
        MockPRDRepository()
    }

    public static func createPRDTemplateRepository(
        withTemplates templates: [PRDTemplate] = []
    ) async -> MockPRDTemplateRepository {
        let repo = MockPRDTemplateRepository()
        if !templates.isEmpty {
            await repo.seed(templates: templates)
        }
        return repo
    }

    public static func createCodebaseRepository(
        searchResults: [(file: CodeFile, similarity: Float)] = []
    ) -> MockPRDCodebaseRepository {
        let repo = MockPRDCodebaseRepository()
        Task {
            await repo.configure(searchResults: searchResults)
        }
        return repo
    }

    // MARK: - Test Domain Objects

    public static func createPRDRequest(
        userId: UUID = UUID(),
        title: String = "Test PRD",
        description: String = "Test description",
        requirements: [Requirement] = [],
        codebaseId: UUID? = nil,
        templateId: UUID? = nil
    ) -> PRDRequest {
        PRDRequest(
            userId: userId,
            title: title,
            description: description,
            requirements: requirements,
            codebaseId: codebaseId,
            templateId: templateId
        )
    }

    public static func createRequirement(
        description: String = "Test requirement",
        priority: Priority = .medium,
        category: RequirementCategory = .functional
    ) -> Requirement {
        Requirement(description: description, priority: priority, category: category)
    }

    public static func createPRDTemplate(
        id: UUID = UUID(),
        name: String = "Test Template",
        description: String = "Test template description",
        sections: [TemplateSectionConfig] = [],
        isDefault: Bool = false
    ) -> PRDTemplate {
        PRDTemplate(
            id: id,
            name: name,
            description: description,
            sections: sections.isEmpty ? defaultSections() : sections,
            isDefault: isDefault,
            createdAt: Date()
        )
    }

    public static func createTemplateSectionConfig(
        sectionType: SectionType,
        order: Int = 0,
        isRequired: Bool = true
    ) -> TemplateSectionConfig {
        TemplateSectionConfig(
            sectionType: sectionType,
            order: order,
            isRequired: isRequired
        )
    }

    public static func createCodeFile(
        id: UUID = UUID(),
        codebaseId: UUID = UUID(),
        projectId: UUID = UUID(),
        filePath: String = "test/Example.swift",
        language: ProgrammingLanguage? = .swift,
        fileSize: Int = 1024
    ) -> CodeFile {
        CodeFile(
            id: id,
            codebaseId: codebaseId,
            projectId: projectId,
            filePath: filePath,
            fileHash: "mock-hash",
            fileSize: fileSize,
            language: language,
            createdAt: Date()
        )
    }

    public static func createPRDSection(
        type: SectionType,
        title: String? = nil,
        content: String = "Test content",
        order: Int = 0
    ) -> PRDSection {
        PRDSection(
            type: type,
            title: title ?? type.displayName,
            content: content,
            order: order
        )
    }

    public static func createPRDDocument(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        title: String = "Test PRD",
        sections: [PRDSection] = []
    ) -> PRDDocument {
        PRDDocument(
            id: id,
            userId: userId,
            title: title,
            sections: sections.isEmpty ? defaultPRDSections() : sections,
            metadata: DocumentMetadata(
                author: "Test Author",
                projectName: title,
                aiProvider: "MockProvider",
                codebaseId: nil
            ),
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Private Helpers

    private static func defaultSections() -> [TemplateSectionConfig] {
        [
            TemplateSectionConfig(sectionType: .overview, order: 0, isRequired: true),
            TemplateSectionConfig(sectionType: .goals, order: 1, isRequired: true),
            TemplateSectionConfig(sectionType: .requirements, order: 2, isRequired: true),
            TemplateSectionConfig(sectionType: .technicalSpecification, order: 3, isRequired: false)
        ]
    }

    private static func defaultPRDSections() -> [PRDSection] {
        [
            PRDSection(type: .overview, title: "Overview", content: "Overview content", order: 0),
            PRDSection(type: .goals, title: "Goals", content: "Goals content", order: 1),
            PRDSection(type: .requirements, title: "Requirements", content: "Requirements content", order: 2)
        ]
    }
}
