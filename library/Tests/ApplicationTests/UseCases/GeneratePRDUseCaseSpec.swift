import XCTest
@testable import Application
@testable import Domain

/// Tests for GeneratePRDUseCase - THE most critical business logic
/// Tests the REAL use case implementation with mock dependencies
final class GeneratePRDUseCaseSpec: XCTestCase {

    // MARK: - Test: Basic PRD Generation

    func testExecute_withBasicRequest_generatesValidPRD() async throws {
        // Given: Basic PRD request without template or codebase
        let request = MockFactory.createPRDRequest(
            title: "User Authentication Feature",
            description: "Add user login and registration",
            requirements: [
                MockFactory.createRequirement(
                    description: "Support email/password login",
                    priority: .high
                ),
                MockFactory.createRequirement(
                    description: "Support OAuth (Google, Apple)",
                    priority: .medium
                )
            ]
        )

        let mockAI = MockFactory.createAIProvider(
            responseMode: .success(mockPRDContent())
        )
        let mockPRDRepo = MockFactory.createPRDRepository()
        let mockTemplateRepo = await MockFactory.createPRDTemplateRepository()

        let useCase = GeneratePRDUseCase(
            aiProvider: mockAI,
            prdRepository: mockPRDRepo,
            templateRepository: mockTemplateRepo
        )

        // When: Execute use case
        let result = try await useCase.execute(request)

        // Then: PRD is generated with correct structure
        XCTAssertEqual(result.title, "User Authentication Feature")
        XCTAssertFalse(result.sections.isEmpty)
        XCTAssertEqual(result.metadata.aiProvider, "MockProvider")

        // Verify AI was called with correct parameters
        let callCount = await mockAI.getCallCount()
        XCTAssertEqual(callCount, 1, "AI provider should be called exactly once")

        let lastPrompt = await mockAI.getLastPrompt()
        XCTAssertNotNil(lastPrompt)
        XCTAssertTrue(
            lastPrompt!.contains("User Authentication Feature"),
            "Prompt should contain the title"
        )
        XCTAssertTrue(
            lastPrompt!.contains("Add user login and registration"),
            "Prompt should contain the description"
        )

        // Verify PRD was saved
        let saveCount = await mockPRDRepo.getSaveCount()
        XCTAssertEqual(saveCount, 1, "PRD should be saved to repository")
    }

    // MARK: - Test: Template-based Generation

    func testExecute_withTemplate_usesTemplateStructure() async throws {
        // Given: Request with custom template
        let template = MockFactory.createPRDTemplate(
            name: "Mobile App Template",
            sections: [
                MockFactory.createTemplateSectionConfig(
                    sectionType: .overview,
                    order: 0,
                    isRequired: true
                ),
                MockFactory.createTemplateSectionConfig(
                    sectionType: .userStories,
                    order: 1,
                    isRequired: true
                ),
                MockFactory.createTemplateSectionConfig(
                    sectionType: .technicalSpecification,
                    order: 2,
                    isRequired: true
                )
            ]
        )

        let request = MockFactory.createPRDRequest(
            title: "Mobile App PRD",
            templateId: template.id
        )

        let mockAI = MockFactory.createAIProvider(
            responseMode: .success(mockPRDContent())
        )
        let mockPRDRepo = MockFactory.createPRDRepository()
        let mockTemplateRepo = await MockFactory.createPRDTemplateRepository(
            withTemplates: [template]
        )

        let useCase = GeneratePRDUseCase(
            aiProvider: mockAI,
            prdRepository: mockPRDRepo,
            templateRepository: mockTemplateRepo
        )

        // When: Execute with template
        let result = try await useCase.execute(request)

        // Then: Template structure is used
        XCTAssertNotNil(result)

        let lastPrompt = await mockAI.getLastPrompt()
        XCTAssertNotNil(lastPrompt)
        XCTAssertTrue(
            lastPrompt!.contains("Mobile App Template"),
            "Prompt should reference template name"
        )
        XCTAssertTrue(
            lastPrompt!.contains("Overview"),
            "Prompt should include template sections"
        )
        XCTAssertTrue(
            lastPrompt!.contains("User Stories"),
            "Prompt should include User Stories section"
        )
    }

    // MARK: - Test: RAG Context Integration

    func testExecute_withCodebase_enrichesPromptWithContext() async throws {
        // Given: Request linked to codebase
        let codebaseId = UUID()
        let request = MockFactory.createPRDRequest(
            title: "API Extension",
            description: "Add new REST endpoints",
            codebaseId: codebaseId
        )

        // Mock codebase files
        let authFile = MockFactory.createCodeFile(
            filePath: "api/AuthController.swift",
            fileSize: 2048
        )
        let userFile = MockFactory.createCodeFile(
            filePath: "models/User.swift",
            fileSize: 1024
        )

        let mockCodebaseRepo = MockFactory.createCodebaseRepository(
            searchResults: [
                (file: authFile, similarity: 0.85),
                (file: userFile, similarity: 0.78)
            ]
        )

        let mockEmbedding = MockFactory.createEmbeddingGenerator()
        let mockAI = MockFactory.createAIProvider(
            responseMode: .success(mockPRDContent())
        )
        let mockPRDRepo = MockFactory.createPRDRepository()
        let mockTemplateRepo = await MockFactory.createPRDTemplateRepository()

        let useCase = GeneratePRDUseCase(
            aiProvider: mockAI,
            prdRepository: mockPRDRepo,
            templateRepository: mockTemplateRepo,
            codebaseRepository: mockCodebaseRepo,
            embeddingGenerator: mockEmbedding
        )

        // When: Execute with codebase
        let result = try await useCase.execute(request)

        // Then: Context is included in prompt
        XCTAssertNotNil(result)

        let lastPrompt = await mockAI.getLastPrompt()
        XCTAssertNotNil(lastPrompt)
        XCTAssertTrue(
            lastPrompt!.contains("Existing Codebase Context"),
            "Prompt should include codebase context section"
        )
        XCTAssertTrue(
            lastPrompt!.contains("AuthController.swift"),
            "Prompt should reference relevant files"
        )
        XCTAssertTrue(
            lastPrompt!.contains("User.swift"),
            "Prompt should reference relevant files"
        )
    }

    // MARK: - Test: Error Handling

    func testExecute_withInvalidRequest_throwsValidationError() async throws {
        // Given: Invalid request (empty title)
        let request = MockFactory.createPRDRequest(
            title: "",  // Invalid
            description: "Test"
        )

        let mockAI = MockFactory.createAIProvider()
        let mockPRDRepo = MockFactory.createPRDRepository()
        let mockTemplateRepo = await MockFactory.createPRDTemplateRepository()

        let useCase = GeneratePRDUseCase(
            aiProvider: mockAI,
            prdRepository: mockPRDRepo,
            templateRepository: mockTemplateRepo
        )

        // When/Then: Should throw validation error
        do {
            _ = try await useCase.execute(request)
            XCTFail("Should throw validation error for empty title")
        } catch {
            // Expected error
            XCTAssertTrue(error is ValidationError)
        }

        // Verify AI was NOT called
        let callCount = await mockAI.getCallCount()
        XCTAssertEqual(callCount, 0, "AI should not be called for invalid request")
    }

    func testExecute_withNonexistentTemplate_throwsError() async throws {
        // Given: Request with non-existent template ID
        let request = MockFactory.createPRDRequest(
            title: "Test PRD",
            templateId: UUID()  // Doesn't exist
        )

        let mockAI = MockFactory.createAIProvider()
        let mockPRDRepo = MockFactory.createPRDRepository()
        let mockTemplateRepo = await MockFactory.createPRDTemplateRepository()

        let useCase = GeneratePRDUseCase(
            aiProvider: mockAI,
            prdRepository: mockPRDRepo,
            templateRepository: mockTemplateRepo
        )

        // When/Then: Should throw error
        do {
            _ = try await useCase.execute(request)
            XCTFail("Should throw error for non-existent template")
        } catch {
            // Expected error - template not found
            XCTAssertTrue(
                "\(error)".contains("Template not found"),
                "Error should indicate template not found"
            )
        }
    }

    func testExecute_whenAIProviderFails_propagatesError() async throws {
        // Given: AI provider configured to fail
        let request = MockFactory.createPRDRequest()

        enum TestError: Error {
            case aiFailure
        }

        let mockAI = MockFactory.createAIProvider(
            responseMode: .failure(TestError.aiFailure)
        )
        let mockPRDRepo = MockFactory.createPRDRepository()
        let mockTemplateRepo = await MockFactory.createPRDTemplateRepository()

        let useCase = GeneratePRDUseCase(
            aiProvider: mockAI,
            prdRepository: mockPRDRepo,
            templateRepository: mockTemplateRepo
        )

        // When/Then: Should propagate AI error
        do {
            _ = try await useCase.execute(request)
            XCTFail("Should propagate AI provider error")
        } catch TestError.aiFailure {
            // Expected error
        } catch {
            XCTFail("Should throw TestError.aiFailure, got \(error)")
        }
    }

    // MARK: - Test: Section Parsing

    func testExecute_parsesAIResponseIntoSections() async throws {
        // Given: AI response with markdown sections
        let aiResponse = """
        ## Overview
        This is the overview section with product vision.

        ## Goals
        - Goal 1: Improve user experience
        - Goal 2: Increase performance

        ## Requirements
        ### Functional Requirements
        - User can login
        - User can logout

        ### Non-Functional Requirements
        - Response time < 200ms
        """

        let request = MockFactory.createPRDRequest(title: "Test PRD")

        let mockAI = MockFactory.createAIProvider(
            responseMode: .success(aiResponse)
        )
        let mockPRDRepo = MockFactory.createPRDRepository()
        let mockTemplateRepo = await MockFactory.createPRDTemplateRepository()

        let useCase = GeneratePRDUseCase(
            aiProvider: mockAI,
            prdRepository: mockPRDRepo,
            templateRepository: mockTemplateRepo
        )

        // When: Execute use case
        let result = try await useCase.execute(request)

        // Then: Sections are correctly parsed
        XCTAssertGreaterThanOrEqual(result.sections.count, 3)

        let overviewSection = result.sections.first { $0.type == .overview }
        XCTAssertNotNil(overviewSection)
        XCTAssertTrue(
            overviewSection!.content.contains("product vision"),
            "Overview content should be parsed"
        )

        let goalsSection = result.sections.first { $0.type == .goals }
        XCTAssertNotNil(goalsSection)
        XCTAssertTrue(
            goalsSection!.content.contains("Improve user experience"),
            "Goals content should be parsed"
        )

        let requirementsSection = result.sections.first { $0.type == .requirements }
        XCTAssertNotNil(requirementsSection)
        XCTAssertTrue(
            requirementsSection!.content.contains("User can login"),
            "Requirements content should be parsed"
        )
    }

    // MARK: - Helpers

    private func mockPRDContent() -> String {
        """
        ## Overview
        Product requirements document for authentication feature.

        ## Goals
        Enable secure user authentication.

        ## Requirements
        Support multiple authentication methods.

        ## Technical Specification
        Use industry-standard security practices.
        """
    }
}
