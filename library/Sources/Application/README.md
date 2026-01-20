# Application Layer (Business Layer Context)

> **Architecture Context:** This layer is part of the **Business Layer** (`library/`) in our Layered Isolation Architecture. Microservices call use cases in this layer via the `LibraryComposition` interface. See [layered-isolation-architecture.md](../../../docs/architecture/layered-isolation-architecture.md) for complete system architecture.

## Purpose
The Application layer orchestrates business logic by coordinating between Domain entities and external services. It contains **use cases** - the specific actions the system can perform.

## Architecture Position

```
MICROSERVICES (backend/Sources/Services/)
    ↓ Call LibraryComposition.useCases.xxx.execute()
BUSINESS LAYER (library/)
    ├── Composition/     ← Public interface (LibraryComposition)
    ├── Application/     ← YOU ARE HERE (use cases, orchestration)
    └── Domain/          ← Business entities and rules
```

**Application Layer Characteristics:**
- Depends **ONLY** on Domain layer (imports Domain)
- **ZERO framework dependencies** (no Vapor, no Supabase, no HTTP)
- Implements business workflows and orchestration
- Uses Domain ports (interfaces), never concrete implementations
- Exposes use cases via `LibraryComposition` interface
- Called by microservices to execute business logic

## Core Responsibility
Define **how** the system accomplishes tasks:
- **How** to generate a PRD from a request?
- **How** to index a codebase for RAG?
- **How** to analyze requirements for clarity?
- **How** to coordinate multiple AI providers?
- **How** to analyze multi-modal inputs (text + mockups + codebase)? (Phase 3)
- **How** to detect missing information gaps and auto-resolve them? (Phase 4)
- **How** to resolve gaps using reasoning, codebase search, or mockup analysis? (Phase 4)
- **How** to manage token budgets across models? (Phase 2)
- **How** to compress context for constrained models? (Phase 2)

The Application layer answers "how to do it" using Domain's "what it is".

## Naming Conventions

> **See `NAMING_CONVENTIONS.md` for comprehensive standards**

**Application Layer Patterns:**
- **Use Cases**: `{Action}{Domain}UseCase` (GeneratePRDUseCase, IndexCodebaseUseCase)
- **DTOs**: `{Action}{Domain}Request/Response` (GeneratePRDRequest, PRDResponse)
- **Errors**: `{Domain}Error` in Application/Errors/ (CodebaseError)
- **Services**: `{Domain}{Purpose}` (PRDOrchestrator, RequirementsAnalyzer)
- **File Naming**: One structure per file, PascalCase (GeneratePRDUseCase.swift)

## Structure

```
Application/
├── UseCases/              # Primary system operations
│   ├── PRD/
│   │   ├── ClarificationEnrichment.swift
│   │   ├── GeneratePRDUseCase.swift
│   │   ├── GetPRDUseCase.swift
│   │   ├── ListPRDsUseCase.swift
│   │   └── SectionGeneration.swift
│   ├── Template/
│   │   ├── CreateTemplateUseCase.swift
│   │   ├── DeleteTemplateUseCase.swift
│   │   ├── GetTemplateUseCase.swift
│   │   ├── ListTemplatesUseCase.swift
│   │   └── UpdateTemplateUseCase.swift
│   ├── Codebase/
│   │   ├── CodebaseSearchResult.swift
│   │   ├── CreateCodebaseUseCase.swift
│   │   ├── IndexCodebaseUseCase.swift
│   │   ├── ListCodebasesUseCase.swift
│   │   └── SearchCodebaseUseCase.swift
│   ├── Clarification/
│   │   └── ClarificationOrchestratorUseCase.swift
│   ├── Integration/       # Repository provider integration
│   │   ├── CodebaseStatusUpdater.swift
│   │   ├── ConnectionTokenRefresher.swift
│   │   ├── ConnectRepositoryProviderUseCase.swift
│   │   ├── DisconnectProviderUseCase.swift
│   │   ├── IndexRemoteRepositoryUseCase.swift
│   │   ├── ListConnectionsUseCase.swift
│   │   ├── ListUserRepositoriesUseCase.swift
│   │   ├── RepositoryContentFetcher.swift
│   │   └── RepositoryURLParser.swift
│   ├── Sessions/          # Session management
│   │   ├── ContinueSessionResult.swift
│   │   ├── ContinueSessionUseCase.swift
│   │   ├── CreateSessionUseCase.swift
│   │   ├── DeleteSessionUseCase.swift
│   │   ├── GetSessionUseCase.swift
│   │   ├── ListSessionsUseCase.swift
│   │   └── MessageIntent.swift
│   └── Thinking/          # Advanced reasoning patterns
│       ├── AnalyzeProblemUseCase.swift
│       ├── ExecuteVerifiedReasoningUseCase.swift
│       ├── GraphOfThoughtsUseCase.swift
│       ├── PlanAndSolveUseCase.swift
│       ├── ReActUseCase.swift
│       ├── ReflexionUseCase.swift
│       ├── ThinkingOrchestratorUseCase.swift
│       └── TreeOfThoughtsUseCase.swift
├── Services/              # Reusable orchestration logic
│   ├── TokenAwareContentGenerator.swift  # Generic token-aware chunking
│   ├── ChunkedJiraGenerator.swift        # JIRA ticket generation
│   ├── JiraTicket.swift                  # JIRA ticket models
│   ├── JiraSubTask.swift                 # JIRA sub-task model
│   ├── JiraTicketFormatter.swift         # Markdown formatting
│   ├── JiraTicketGeneratorService.swift  # Legacy JIRA generator
│   ├── JiraTicketType.swift              # Epic/Story/Task/Sub-task
│   ├── JiraPriority.swift                # Critical/High/Medium/Low
│   ├── PRDPromptBuilder.swift            # PRD prompt builder
│   ├── PRDSectionParser.swift            # PRD section parser
│   ├── PromptEngineeringService.swift    # Generic prompt engineering
│   ├── PromptEngineeringError.swift      # Prompt engineering errors
│   ├── Tokenization/      # Token budget management
│   │   ├── TokenBudgetService.swift
│   │   ├── ModelAwareBudgetAllocator.swift
│   │   └── SelfBudgeter.swift
│   ├── Chunking/          # Content chunking orchestration
│   │   └── ChunkingOrchestrator.swift
│   ├── Compression/       # Context compression services
│   │   ├── AppleIntelligenceContextCompressor.swift
│   │   └── TokenSkipCompressor.swift
│   ├── Clarification/     # Requirement clarification services
│   │   ├── AdaptiveAnalysisService.swift
│   │   ├── AdaptiveAnalysisError.swift
│   │   ├── AdaptiveTemperatureStrategy.swift
│   │   ├── RequirementAnalyzerService.swift
│   │   ├── RequirementAnalyzerError.swift
│   │   ├── RequirementAnalysisParser.swift
│   │   ├── RequirementAnalysisPromptBuilder.swift
│   │   └── SectionClarificationService.swift
│   ├── PromptBuilder/     # Prompt template base classes
│   │   └── BasePromptTemplate.swift
│   ├── PRD/               # PRD-specific services (Phase 9.3.2)
│   │   ├── ContextBudgetAllocator.swift
│   │   ├── CoreSectionBuilders.swift
│   │   ├── EnrichedContextBuilder.swift
│   │   ├── EnrichedContextFormatter.swift
│   │   ├── EnrichedContextInjector.swift
│   │   ├── MockupAssociationService.swift
│   │   ├── QualitySectionBuilders.swift
│   │   ├── SectionContextExtractor.swift
│   │   └── TechnicalSectionBuilders.swift
│   ├── MultiModal/        # Multi-modal input analysis (Phase 3)
│   │   ├── ContextAggregator.swift
│   │   ├── InputAnalysisOrchestrator.swift
│   │   └── MultiModalAnalysisService.swift
│   ├── RAG/               # RAG orchestration services
│   │   ├── CodeContextFormatter.swift
│   │   ├── ContextAwareFilter.swift
│   │   ├── ContextGraphTracker.swift
│   │   ├── ContextRetrievalOrchestrator.swift
│   │   ├── CoTRAGRetriever.swift
│   │   ├── GraphEnricher.swift
│   │   ├── HybridSearchService.swift
│   │   ├── QueryExpansionService.swift
│   │   └── RerankingService.swift
│   └── Thinking/          # Thinking pattern services (50+ files)
│       ├── BaseStrategy.swift
│       ├── ConfidenceCalibrator.swift
│       ├── EnhancementType.swift
│       ├── ExecutionPlan.swift
│       ├── GraphConnectionAnalyzer.swift
│       ├── GraphNodeGenerator.swift
│       ├── GraphSynthesizer.swift
│       ├── MultiHopReasoningEngine.swift
│       ├── PlanExecutor.swift
│       ├── PlanParser.swift
│       ├── PlanRefiner.swift
│       ├── PlanStep.swift
│       ├── PlanVerification.swift
│       ├── PlanVerifier.swift
│       ├── ProblemCharacteristics.swift
│       ├── QualityMetricsCalculator.swift
│       ├── ReActActionExecutor.swift
│       ├── ReActCycleBuilder.swift
│       ├── ReasoningContextBuilder.swift
│       ├── ReasoningRefiner.swift
│       ├── ReasoningVerifier.swift
│       ├── ReflectionAnalyzer.swift
│       ├── ReflectionEntry.swift
│       ├── ReflectionMemoryFormatter.swift
│       ├── ReliabilityAssessment.swift
│       ├── ReliabilityAssessor.swift
│       ├── StepResult.swift
│       ├── StrategyResult.swift
│       ├── StructuredCoTParser.swift
│       ├── StructuredCoTPromptBuilder.swift
│       ├── ThinkingStrategy.swift
│       ├── ThinkingStrategyExecutor.swift
│       ├── ThinkingStrategySelector.swift
│       ├── ThoughtChainRefiner.swift
│       ├── TreeBranchGenerator.swift
│       ├── TreeBuilder.swift
│       ├── TreeNodeEvaluator.swift
│       ├── TRMEnhancementService.swift
│       ├── TRMHaltingEvaluator.swift
│       ├── TRMIterationEngine.swift
│       ├── TRMPromptBuilder.swift
│       ├── TRMResponseParser.swift
│       ├── TRMStateTracker.swift
│       └── Internal/          # Internal thinking components
│           ├── ConnectionComponents.swift
│           ├── ConsistencyCheck.swift
│           ├── GroundingCheck.swift
│           ├── HallucinationAssessment.swift
│           └── StepComponents.swift
├── DTOs/                  # Data transfer objects (40 files)
│   ├── AdaptiveAnalysisResult.swift
│   ├── ClarificationResult.swift
│   ├── PRDRequest.swift
│   ├── PRDRequestError.swift
│   ├── Requirement.swift
│   ├── PRD/               # PRD-specific DTOs
│   │   ├── EnrichedPRDContext.swift
│   │   ├── PromptBudget.swift
│   │   ├── RAGSearchResults.swift
│   │   ├── ReasoningPlan.swift
│   │   └── SectionContext.swift
│   ├── MultiModal/        # Multi-modal analysis DTOs (Phase 3)
│   │   ├── AggregatedContext.swift
│   │   ├── CodebaseContext.swift
│   │   ├── CodeInsights.swift
│   │   ├── DataInsights.swift
│   │   ├── InputAnalysisRequest.swift
│   │   ├── MultiModalAnalysisResult.swift
│   │   └── UIInsights.swift
│   ├── RAG/               # RAG-specific DTOs
│   │   ├── ContextualRetrievalResult.swift
│   │   ├── ExpandedQuery.swift
│   │   ├── FusionScore.swift
│   │   ├── HybridSearchResult.swift
│   │   ├── KeywordSearchResult.swift
│   │   ├── RankedChunk.swift
│   │   ├── RetrievalMetadata.swift
│   │   └── ScoredChunk.swift
│   └── Thinking/          # Thinking result DTOs (25+ files)
│       ├── EnhancedResult.swift
│       ├── IterationResult.swift
│       ├── ParsedReasoning.swift
│       ├── PlanAndSolveResult.swift
│       ├── QualityMetrics.swift
│       ├── ReActAction.swift
│       ├── ReActActionResult.swift
│       ├── ReActActionType.swift
│       ├── ReActResult.swift
│       ├── ReActStep.swift
│       ├── ReasoningStyle.swift
│       ├── ReflexionResult.swift
│       ├── ThinkingResult.swift
│       ├── TRMResult.swift
│       ├── VerificationResult.swift
│       └── VerifiedReasoningResult.swift
├── ValueObjects/          # Application-level value types (0 files currently)
└── Errors/                # Application-specific errors
    ├── CodebaseError.swift
    └── ExecutionError.swift
```

**Note:** DTOs represent application-level input/output, not core domain entities. Error types specific to application workflows are placed in Application/Errors/.

**Key observations:**
- **Actual Services count: 96 files** (significantly more than documented)
- **Thinking/ subdirectory**: Contains 50+ files for advanced reasoning patterns (TRM, ReAct, Reflexion, Graph of Thoughts, etc.)
- **Clarification/ subdirectory**: New directory for requirement clarification services (not in original docs)
- **Integration/ use cases**: Repository provider integration (GitHub, GitLab, etc.)
- **Sessions/ use cases**: Session management for conversational PRD generation
- **PromptBuilder/**: Base classes for prompt templates
- **RAG/ expansion**: Additional services like CoTRAGRetriever, ContextGraphTracker
- **PRD/ expansion**: EnrichedContext services, budget allocation, mockup association

## Token-Aware Content Generation

### Generic System (`TokenAwareContentGenerator`)

A **fully generic, type-safe** token-aware content generator that handles chunking for any AI generation task:

```swift
public struct TokenAwareContentGenerator<Content, Result>: Sendable
    where Content: Sendable, Result: Sendable {

    public func generate(
        items: [Content],
        estimateTokens: @escaping (Content) async throws -> Int,
        processChunk: @escaping ([Content], Int, Int) async throws -> [Result]
    ) async throws -> [Result]
}
```

**Key Features:**
- **Generic over input/output types** - Reusable for any content generation
- **Token budget management** - Configurable context windows (4K-200K tokens)
- **Smart chunking** - Breaks content into token-budget chunks
- **Provider-agnostic** - Works with any `TokenizerPort` implementation

**Type Aliases:**
```swift
/// For PRD section generation
typealias SectionTokenGenerator = TokenAwareContentGenerator<PRDSection, PRDSection>

/// For JIRA ticket generation
typealias JiraTokenGenerator = TokenAwareContentGenerator<PRDSection, JiraTicket>
```

**Usage Example:**
```swift
let generator = JiraTokenGenerator(
    tokenizer: appleTokenizer,
    maxContextTokens: 4096
)

let tickets = try await generator.generate(
    items: document.sections,
    estimateTokens: { section in
        try await generator.countTokens(in: section.content)
    },
    processChunk: { sections, chunkIndex, totalChunks in
        try await generateTicketsForChunk(sections)
    }
)
```

**Benefits:**
- ✅ **DRY compliance** - Single source of truth for token-aware chunking
- ✅ **Type safety** - Compile-time guarantees via generics
- ✅ **Testability** - Mock `TokenizerPort` easily
- ✅ **Extensibility** - Add new generators by specializing the generic

## Design Principles

### 1. Use Case Pattern
Each use case is a **single user action**:
```swift
// ✅ GOOD: One clear responsibility
public struct GeneratePRDUseCase {
    private let aiProvider: AIProviderPort
    private let repository: PRDRepositoryPort

    public func execute(_ request: PRDRequest) async throws -> PRDDocument {
        // Orchestrate: validate → generate → persist → return
    }
}
```

Each use case:
- Has one `execute()` method (or similar)
- Coordinates Domain entities
- Uses ports, not implementations
- Returns Domain entities or DTOs

### 2. Dependency Injection via Ports
Use cases depend on **protocols** from Domain:
```swift
// ✅ GOOD: Depends on abstraction
public struct IndexCodebaseUseCase {
    private let codeParser: CodeParserPort          // Port
    private let repository: CodebaseRepositoryPort  // Port
    private let embedder: EmbeddingGeneratorPort    // Port

    public init(
        codeParser: CodeParserPort,
        repository: CodebaseRepositoryPort,
        embedder: EmbeddingGeneratorPort
    ) {
        self.codeParser = codeParser
        self.repository = repository
        self.embedder = embedder
    }
}

// ❌ BAD: Depends on concrete implementation
public struct IndexCodebaseUseCase {
    private let parser = SwiftParser()  // ❌ Concrete
    private let db = SupabaseRepo()     // ❌ Concrete
}
```

### 3. Method Size Discipline
Keep methods ≤ 40 lines by extracting helpers:
```swift
// ✅ GOOD: Extracted helpers
public func execute(_ request: PRDRequest) async throws -> PRDDocument {
    try validateRequest(request)

    let prompt = buildPrompt(from: request)
    let context = try await gatherContext(for: request)
    let content = try await generateContent(prompt: prompt, context: context)
    let sections = parseSections(from: content)

    return try await persistDocument(
        createDocument(request: request, sections: sections)
    )
}

private func validateRequest(_ request: PRDRequest) throws { ... }
private func buildPrompt(from request: PRDRequest) -> String { ... }
private func gatherContext(for request: PRDRequest) async throws -> String { ... }
// ... etc, all < 40 lines
```

### 4. Business Workflow, Not Business Rules
Application orchestrates, Domain validates:
```swift
// ✅ GOOD: Application orchestrates
public struct GeneratePRDUseCase {
    func execute(_ request: PRDRequest) async throws -> PRDDocument {
        try request.validate()  // ✅ Domain validates

        let content = try await aiProvider.generateText(...)
        let document = PRDDocument(...)  // ✅ Domain entity

        try document.validate()  // ✅ Domain validates again
        return try await repository.save(document)
    }
}

// ❌ BAD: Application contains business rules
public struct GeneratePRDUseCase {
    func execute(_ request: PRDRequest) async throws -> PRDDocument {
        if request.title.count < 5 {  // ❌ Business rule in application
            throw Error.titleTooShort
        }
        if request.description.isEmpty {  // ❌ Should be in Domain
            throw Error.missingDescription
        }
    }
}
```

## Key Patterns

### Use Cases
**Purpose**: Execute a single user action from start to finish

**Structure**:
```swift
public struct [Action]UseCase {
    // Dependencies (ports only)
    private let port1: SomePort
    private let port2: AnotherPort

    // Constructor injection
    public init(port1: SomePort, port2: AnotherPort) {
        self.port1 = port1
        self.port2 = port2
    }

    // Single entry point
    public func execute(_ input: InputType) async throws -> OutputType {
        // Orchestration logic
    }
}
```

**Examples**:
- `GeneratePRDUseCase`: Create PRD from request (supports templates)
- `CreateTemplateUseCase`: Create reusable PRD template
- `IndexCodebaseUseCase`: Index code for RAG
- `ValidatePRDUseCase`: Check PRD quality
- `SearchCodebaseUseCase`: Find relevant code

### Application Services
**Purpose**: Reusable orchestration logic shared by multiple use cases

**When to Use**: When logic is needed by 2+ use cases
```swift
// Service used by multiple use cases
public struct PRDOrchestrator {
    private let analyzer: RequirementsAnalyzer
    private let generator: SectionGenerator

    public func orchestrateGeneration(
        from input: ProcessedInput
    ) async throws -> PRDDocument {
        // Multi-phase generation logic
        // Used by GeneratePRDUseCase, RegeneratePRDUseCase, etc.
    }
}
```

### DTOs (Data Transfer Objects)
**Purpose**: Move data between layers without coupling

**Characteristics**:
- Simple data containers
- No business logic
- May have validation
- Often Codable for serialization

```swift
public struct PRDRequest: Codable {
    public let title: String
    public let description: String
    public let requirements: [String]
    public let codebaseId: UUID?

    public func validate() throws {
        guard !title.isEmpty else {
            throw PRDError.invalidRequest("Title required")
        }
    }
}
```

## Integration Points

### Consumes From Domain
- **Entities**: PRDDocument, ThoughtChain, Codebase
- **Ports**: AIProviderPort, RepositoryPorts, ParserPorts
- **Value Objects**: SectionType, Priority, etc.
- **Errors**: Domain-defined error types

### Provides To Infrastructure
- **Use Cases**: Entry points for external triggers (API, CLI)
- **Workflows**: Defined processes to implement
- **Requirements**: What ports must be implemented

### Provides To Composition
- **Public API**: Use case interfaces for DI wiring
- **Orchestration**: Complete workflows ready to execute

## Use Case Examples

### Simple Use Case (Direct Flow)
```swift
public struct GetPRDUseCase {
    private let repository: PRDRepositoryPort

    public init(repository: PRDRepositoryPort) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws -> PRDDocument? {
        try await repository.findById(id)
    }
}
```

### Complex Use Case (Multi-Step Orchestration)
```swift
public struct GeneratePRDUseCase {
    private let aiProvider: AIProviderPort
    private let repository: PRDRepositoryPort
    private let codebaseRepo: CodebaseRepositoryPort?
    private let embedder: EmbeddingGeneratorPort?

    public func execute(_ request: PRDRequest) async throws -> PRDDocument {
        // Step 1: Validate
        try validateRequest(request)

        // Step 2: Build base prompt
        let prompt = buildPrompt(from: request)

        // Step 3: Enrich with RAG if codebase linked
        let enrichedPrompt = try await enrichWithContext(
            prompt,
            codebaseId: request.codebaseId
        )

        // Step 4: Generate content
        let content = try await generateContent(
            prompt: enrichedPrompt
        )

        // Step 5: Parse and structure
        let sections = parseSections(from: content)

        // Step 6: Create and validate domain entity
        let document = createDocument(
            request: request,
            sections: sections
        )
        try document.validate()

        // Step 7: Persist
        return try await repository.save(document)
    }

    // Each helper < 40 lines
    private func validateRequest(_ request: PRDRequest) throws { ... }
    private func buildPrompt(from request: PRDRequest) -> String { ... }
    private func enrichWithContext(...) async throws -> String { ... }
    private func generateContent(prompt: String) async throws -> String { ... }
    private func parseSections(from content: String) -> [PRDSection] { ... }
    private func createDocument(...) -> PRDDocument { ... }
}
```

## Design Constraints

### Must
- ✅ Import Domain only
- ✅ Depend on ports, not implementations
- ✅ Keep use cases focused (single responsibility)
- ✅ Extract methods to stay ≤ 40 lines
- ✅ Return Domain entities or DTOs

### Must Not
- ❌ Import Infrastructure layer
- ❌ Instantiate concrete implementations
- ❌ Contain business validation rules (Domain's job)
- ❌ Have UI logic or presentation concerns
- ❌ Access databases/APIs directly

## Testing Strategy

Application layer tests use **mocked ports**:
```swift
// Mock implementation of port
final class MockAIProvider: AIProviderPort {
    var generateTextCallCount = 0
    var mockResponse: String = ""

    func generateText(prompt: String) async throws -> String {
        generateTextCallCount += 1
        return mockResponse
    }
}

// Test use case
func testGeneratePRD() async throws {
    let mockAI = MockAIProvider()
    mockAI.mockResponse = "# PRD Content"

    let mockRepo = MockPRDRepository()

    let useCase = GeneratePRDUseCase(
        aiProvider: mockAI,
        repository: mockRepo
    )

    let result = try await useCase.execute(validRequest)

    XCTAssertEqual(mockAI.generateTextCallCount, 1)
    XCTAssertEqual(mockRepo.saveCallCount, 1)
    XCTAssertEqual(result.title, "Test PRD")
}
```

## Common Violations to Avoid

### ❌ Importing Infrastructure
```swift
// BAD
import Infrastructure  // ❌

public struct GeneratePRDUseCase {
    private let provider = OpenAIProvider()  // ❌
}
```

### ❌ Business Rules in Use Cases
```swift
// BAD: Validation belongs in Domain
public struct GeneratePRDUseCase {
    func execute(_ request: PRDRequest) async throws -> PRDDocument {
        if request.sections.count < 3 {  // ❌ Business rule
            throw Error.incomplete
        }
    }
}
```

### ❌ Methods Too Large
```swift
// BAD: 80-line method
public func execute(_ request: PRDRequest) async throws -> PRDDocument {
    // ... 80 lines of orchestration without extraction
}
```

### ❌ Multiple Responsibilities
```swift
// BAD: Does too much
public struct PRDUseCase {
    func generate() { ... }
    func validate() { ... }
    func export() { ... }
    func email() { ... }
}
```

## Adding New Use Cases

Checklist for new use cases:

1. **Identify** the single user action
2. **Define** input (request/DTO) and output (entity/DTO)
3. **List** required ports from Domain
4. **Design** orchestration flow
5. **Extract** methods to keep each < 40 lines
6. **Implement** with dependency injection
7. **Test** with mocked ports

Example:
```swift
// 1. Action: "Analyze PRD for conflicts"
// 2. Input: PRDDocument, Output: ConflictReport
// 3. Ports needed: ConflictDetectorPort
// 4. Flow: load document → analyze → generate report
// 5. Extract: loadDocument(), analyzeConflicts(), generateReport()
// 6. Inject port via constructor
// 7. Test with MockConflictDetector
```

## Phase 3: Multi-Modal Input Analysis Pattern

### Overview
Phase 3 introduces **multi-modal input analysis** - combining text descriptions, UI mockups, and codebase context for comprehensive PRD generation.

### Architecture Pattern
```
InputAnalysisRequest
    ↓
InputAnalysisOrchestrator (strategy selection)
    ↓
MultiModalAnalysisService (parallel analysis)
    ├─→ VisionAnalysisPort (mockup analysis)
    ├─→ CodebaseRepositoryPort (code context)
    └─→ Text processing
    ↓
MultiModalAnalysisResult
    ↓
ContextAggregator (unification)
    ├─→ Extract UIInsights
    ├─→ Extract DataInsights
    └─→ Extract CodeInsights
    ↓
AggregatedContext (ready for PRD generation)
```

### Strategy Selection
**InputAnalysisOrchestrator** selects optimal strategy based on inputs:
- **Comprehensive**: text + mockups + codebase
- **MockupFocused**: text + mockups only
- **CodebaseFocused**: text + codebase only
- **TextOnly**: text description only

### Service Responsibilities

**MultiModalAnalysisService**:
- Orchestrates parallel analysis of all input types
- Analyzes mockups concurrently (one per image)
- Extracts user flows across multiple screens
- Fetches relevant codebase context (limited to 50 chunks)
- Combines results into unified structure

**ContextAggregator**:
- Extracts insights from each input source
- Categorizes UI components by type
- Identifies data requirements and validation rules
- Analyzes codebase patterns and languages
- Detects cross-cutting concerns (auth, persistence, validation)

### Example Usage
```swift
let orchestrator = InputAnalysisOrchestrator(
    multiModalService: multiModalService,
    contextAggregator: contextAggregator
)

let request = InputAnalysisRequest(
    textDescription: "Build a user profile screen",
    mockupImages: [profileMockup, settingsMockup],
    codebaseId: existingProjectId
)

// Strategy auto-selected: .comprehensive
let context = try await orchestrator.orchestrateAnalysis(request)

// Context contains:
// - UIInsights: 12 screens, 47 components, 3 user flows
// - DataInsights: 8 fields, 5 required, validation rules
// - CodeInsights: Swift, 127 files, existing patterns
// - CrossCuttingConcerns: ["Authentication", "Data Persistence"]
```

### DTOs Created (Phase 3)
- `InputAnalysisRequest`: Multi-modal input request
- `MultiModalAnalysisResult`: Combined analysis result
- `AggregatedContext`: Unified context for PRD generation
- `CodebaseContext`: Codebase context summary
- `UIInsights`: UI component and flow analysis
- `DataInsights`: Data field and validation analysis
- `CodeInsights`: Code pattern and language analysis

### Value Objects (Phase 3)
- `AnalysisStrategy`: Strategy enum (comprehensive, mockupFocused, etc.)
- `InputComplexity`: Complexity level (low, medium, high)

### Integration with PRD Generation
The `AggregatedContext` output feeds directly into PRD generation use cases, providing rich, multi-source context for comprehensive document creation.

## Phase 4: Gap Detection & Self-Resolution Pattern

### Overview
Phase 4 introduces **intelligent gap detection and self-resolution** - automatically identifying missing information during PRD generation and resolving 70%+ of gaps without user intervention.

### Architecture Pattern
```
PRD Generation
    ↓
GapDetectionService (identify missing information)
    ↓
GapCategorizationService (categorize by type & priority)
    ↓
GapResolutionService (orchestrate resolution attempts)
    ├─→ ReasoningResolutionService (CoT reasoning)
    ├─→ CodebaseResolutionService (ReAct search)
    ├─→ MockupResolutionService (vision analysis)
    └─→ User Query (if confidence < 70%)
    ↓
ConfidenceScorer (evaluate resolution quality)
    ├─→ Auto-apply (> 90% confidence)
    ├─→ Present with caveat (70-90% confidence)
    └─→ Ask user (< 70% confidence)
    ↓
Resolved Information (integrated into PRD)
```

### Gap Categories (8 types)
**GapDetectionService** identifies gaps across:
- **Authentication**: OAuth methods, session management, security
- **Data Model**: Schemas, relationships, validation rules
- **Scalability**: Load patterns, caching, database optimization
- **User Experience**: Navigation, feedback, accessibility
- **Integration**: Third-party APIs, webhooks, external services
- **Security**: Encryption, authorization, compliance
- **Business Logic**: Workflows, calculations, state machines
- **Deployment**: Infrastructure, CI/CD, monitoring

### Resolution Strategies (5 approaches)
**GapResolutionService** attempts resolution using:

1. **Reasoning** (60-80% confidence)
   - Uses ChainOfThoughtUseCase for logical inference
   - Analyzes context and patterns to deduce answers
   - Best for architectural and business logic questions

2. **Codebase Search** (85-95% confidence)
   - Uses ReActUseCase for intelligent code search
   - Finds existing implementations, patterns, libraries
   - Highest confidence for technical decisions

3. **Mockup Analysis** (80-90% confidence)
   - Uses VisionAnalysisPort to extract UX details
   - Identifies UI patterns, flows, component states
   - Strong confidence for user experience questions

4. **User Query** (100% confidence)
   - Falls back to asking user when automation fails
   - Used when confidence < 70% on all strategies
   - Guarantees accurate information

5. **Informed Assumption** (40-60% confidence)
   - Makes educated guesses based on best practices
   - Only used with user consent and clear disclaimers
   - Lowest confidence, requires validation

### Service Responsibilities

**GapDetectionService**:
- Analyzes PRD sections for completeness
- Identifies missing information across 8 categories
- Generates specific questions that need answers
- Prioritizes gaps (critical, high, medium, low)

**GapCategorizationService**:
- Maps detected gaps to appropriate categories
- Assigns priority based on impact and urgency
- Groups related gaps for batch resolution
- Determines optimal resolution strategy

**GapResolutionService**:
- Orchestrates multi-strategy resolution attempts
- Tries strategies in order of expected confidence
- Tracks all attempts with evidence and reasoning
- Decides when to ask user vs auto-resolve

**CodebaseResolutionService**:
- Searches indexed codebase for answers
- Uses ReActUseCase for intelligent retrieval
- Extracts relevant patterns and implementations
- Provides file references as evidence

**MockupResolutionService**:
- Analyzes mockups for UX clarity
- Uses VisionAnalysisPort for component extraction
- Identifies user flows and interactions
- Resolves UI/UX related gaps

**ReasoningResolutionService**:
- Applies CoT reasoning to infer answers
- Uses domain knowledge and context
- Logical deduction for architectural decisions
- Validates reasoning with confidence scoring

**ConfidenceScorer**:
- Evaluates resolution quality and confidence
- Decides auto-apply vs present vs ask user
- Calibrates scores based on historical accuracy
- Provides transparency on decision rationale

### Example Usage
```swift
let gapDetector = GapDetectionService(
    gapDetectionPort: gapDetectionAdapter
)

let gapResolver = GapResolutionService(
    reasoningService: reasoningService,
    codebaseService: codebaseService,
    mockupService: mockupService,
    confidenceScorer: confidenceScorer
)

// Detect gaps during PRD generation
let gaps = try await gapDetector.detectGaps(
    sections: prdSections,
    context: generationContext
)

// Auto-resolve gaps
for gap in gaps {
    let attempts = try await gapResolver.resolveGap(gap)

    if let bestAttempt = attempts.max(by: { $0.confidence < $1.confidence }),
       bestAttempt.confidence.score > 0.90 {
        // Auto-apply high confidence resolution
        applyResolution(gap, bestAttempt)
    } else if bestAttempt.confidence.score > 0.70 {
        // Present to user with caveat
        presentWithWarning(gap, bestAttempt)
    } else {
        // Ask user
        askUser(gap)
    }
}
```

### Domain Components (Phase 4.1 Complete)
**Entities:**
- `InformationGap`: Tracks detected gaps with category, priority, question, context
- `ResolutionAttempt`: Records resolution attempts with strategy, result, confidence, evidence

**Value Objects:**
- `GapCategory`: 8 gap categories (authentication, dataModel, scalability, etc.)
- `GapPriority`: Priority levels (critical, high, medium, low)
- `ResolutionStrategy`: 5 strategies (reasoning, codebaseSearch, mockupAnalysis, userQuery, informedAssumption)
- `ResolutionConfidence`: Confidence score with reasoning and sources
- Plus 9 supporting types (GapContext, GapStatus, ResolutionResult, etc.)

**Ports:**
- `GapDetectionPort`: Interface for gap detection and categorization

**Errors:**
- `GapResolutionError`: Domain-specific errors for gap resolution

### Expected Capabilities
- **Gap Detection**: Identify 95%+ of missing information
- **Auto-Resolution**: Resolve 70%+ without user input
  - 85%+ for codebase questions (ReAct search)
  - 75%+ for UX questions (mockup analysis)
  - 60%+ for architectural questions (CoT reasoning)
- **Confidence Thresholds**:
  - > 90%: Auto-apply
  - 70-90%: Present with caveat
  - < 70%: Ask user
- **Evidence Tracking**: Full audit trail of attempts and sources

### Integration with Existing Patterns
- **ChainOfThoughtUseCase**: Reasoning-based gap resolution
- **ReActUseCase**: Codebase search gap resolution
- **VisionAnalysisPort**: Mockup-based gap resolution
- **HybridSearchService**: Finding similar patterns for context
- **Streaming Generation**: Progressive gap detection and resolution

### Success Metrics
- 70%+ auto-resolution rate
- < 5% false positive resolutions
- User satisfaction: 4.5+ / 5 for auto-resolved answers
- Time savings: 60%+ reduction in back-and-forth questions

## Phase 9.3.2: Multi-Pass PRD Generation (COMPLETE)

### Overview

Solves **Apple Intelligence 8K token limit** through section-by-section generation with focused context extraction.

### Problem
Apple Foundation Models has an 8K token context window. Single-pass PRD generation attempted 20K+ token prompts, causing failures.

### Solution
**Multi-pass generation** - 6 separate AI calls, each with focused context <8K tokens.

### Architecture
```
GeneratePRDUseCase (orchestrates multi-pass loop)
    ↓
For each section (6 core sections):
    ├─→ SectionContextExtractor (extract focused context)
    ├─→ PRDPromptBuilder (build section prompt <8K tokens)
    ├─→ AI Provider (generate ONLY this section)
    └─→ Assemble into complete PRD
```

### Services

**SectionContextExtractor**:
- Extracts ONLY relevant context for each section type
- 14 dedicated context builders (one per section type)
- Keeps prompts small and focused
- Split into 3 files for maintainability:
  - `CoreSectionBuilders.swift` - Overview, Goals, Requirements (73 lines)
  - `TechnicalSectionBuilders.swift` - Technical, API, DataModel, Security, Performance (138 lines)
  - `QualitySectionBuilders.swift` - UserStories, Acceptance, Testing, Deployment, Risks, Timeline (136 lines)

**Context Extraction Strategy:**
- **Overview**: Top 5 requirements, platform, target audience
- **Goals**: All requirements with priorities, success criteria from metadata
- **Requirements**: All requirements, all constraints, platform
- **Technical**: Technical requirements (filtered), platform, tech stack, architecture
- **User Stories**: Requirements as features, personas, user flows, audience
- **Acceptance Criteria**: Requirements to validate, constraints, test scenarios

### Integration
- `GeneratePRDUseCase` loops through 6 sections
- Each section gets focused context via `SectionContextExtractor`
- `PRDPromptBuilder` builds section-specific prompts
- Progress indicators: "⏳ [1/6] Generating Overview..."
- Real-time feedback: "✅ [1/6] Overview complete"

### Benefits
- ✅ Works with Apple Intelligence (each prompt <8K tokens)
- ✅ Professional output (uses sophisticated templates)
- ✅ Focused context (no noise per section)
- ✅ Progressive generation (partial results visible)
- ✅ User experience (real-time progress)

### Trade-offs
- ⚠️ 6 AI calls instead of 1 (higher cost)
- ⚠️ Sequential generation (longer time)
- ⚠️ Context fragmentation (sections don't see each other)

**See:** ADR-011 for full decision rationale

---

## Phase 9.3.1: PRD Prompt Engineering (COMPLETE)

### Overview

Transforms generic PRD generation into **professional, high-quality output** through sophisticated section-by-section prompting.

### Services

**PromptEngineeringService**:
- Generates section-specific prompts with context injection
- Variable replacement ({title}, {description}, {requirements})
- Template-based prompt strategies
- Fallback handling for missing templates

**PRDPromptBuilder**:
- Builds sophisticated multi-section prompts
- Delegates to PromptEngineeringService when available
- Enriches prompts with codebase context (RAG)
- Supports template-based and base prompt strategies

**PRDSectionParser**:
- Parses AI-generated content into structured sections
- Markdown parsing with section type detection
- Handles various section heading formats

### Prompt Templates (Infrastructure)
- `OverviewPromptTemplate`: Problem statement, solution, scope (200-300 words)
- `GoalsPromptTemplate`: SMART goals with metrics (300-400 words)
- `RequirementsPromptTemplate`: Functional/non-functional, prioritized (400-500 words)
- `TechnicalSpecificationPromptTemplate`: Architecture, tech stack, APIs (500-700 words)
- `UserStoriesPromptTemplate`: Personas and user journeys (300-400 words)
- `AcceptanceCriteriaPromptTemplate`: Testable criteria (200-300 words)

### Quality Improvements
- **Before**: Generic 50-100 word sections
- **After**: Professional 200-700 word sections with specific details, metrics, and rationale

### Integration
- `GeneratePRDUseCase` uses `PRDPromptBuilder` for all prompt construction
- Supports both basic prompts (fallback) and sophisticated prompts (when PromptEngineeringService available)
- Automatic section-by-section generation with tailored instructions

---

## Phase 4.6: Adaptive TRM Meta-Enhancement

### Overview

TRM (Tiny Recursion Model) is a **meta-enhancement layer** that amplifies any reasoning technique through recursive refinement with **statistical halting** instead of arbitrary thresholds.

### Architecture Pattern
```
Base Strategy Result
    ↓
TRMEnhancementService
    ├─→ Recursive refinement loop
    ├─→ Statistical convergence detection (ConvergenceEvidence)
    ├─→ Adaptive halting (AdaptiveHaltingPolicy)
    ├─→ Oscillation prevention (binomial distribution)
    └─→ Diminishing returns detection (relative slope)
    ↓
Enhanced Result (higher quality, optimal iterations)
```

### TRMEnhancementService (Complete)
```swift
public struct TRMEnhancementService: Sendable {
    private let haltingEvaluator: TRMHaltingEvaluator

    public func enhance<T: RefinableResult>(
        baseResult: T,
        problem: String,
        context: String,
        refiner: Refiner<T>,
        config: TRMConfig
    ) async throws -> EnhancedResult<T> {
        // Uses ConvergenceEvidence for statistical analysis
        // Adaptive halting based on user policy
    }
}
```

### Statistical Foundation: ConvergenceEvidence

**Revolutionary Change**: No hardcoded thresholds, all metrics computed from trajectory data.

```swift
public struct ConvergenceEvidence: Sendable {
    // Computed from trajectory (no arbitrary values)
    public let coefficientOfVariation: Double  // σ/μ (ISO standard)
    public let trendSlope: Double              // Linear regression
    public let varianceRatio: Double           // Recent/initial variance
    public let oscillationCount: Int           // Sign changes
    public let convergenceProbability: Double  // 0-1 from evidence

    // Decisions based on statistical tests
    public var showsStrongConvergence: Bool {
        convergenceProbability > 0.90  // Data-driven threshold
    }

    public var showsOscillation: Bool {
        // Binomial distribution: count > μ + σ
        let expectedFlips = Double(trajectory.count) / 2.0
        let stdDev = sqrt(Double(trajectory.count))
        return Double(oscillationCount) > expectedFlips + stdDev
    }

    public var showsDiminishingReturns: Bool {
        // Slope < 1% of mean (relative measure)
        let mean = trajectory.reduce(0.0, +) / Double(trajectory.count)
        return abs(trendSlope) < (mean * 0.01)
    }
}
```

### Adaptive Halting: User Preference vs Statistical Evidence

```swift
public struct AdaptiveHaltingPolicy: Sendable {
    /// User's confidence requirement (0.5-0.99)
    /// This is USER PREFERENCE, not arbitrary threshold
    public let minConvergenceProbability: Double

    /// Safety limit (prevents infinite loops)
    public let maxIterations: Int

    /// Task-specific quality goal
    public let targetQuality: Double

    // Decision: Compare evidence to user requirement
    public func shouldHaltOnConvergence(_ evidence: ConvergenceEvidence) -> Bool {
        evidence.convergenceProbability >= minConvergenceProbability
    }

    // Presets (user preference profiles)
    public static let strict = AdaptiveHaltingPolicy(
        minConvergenceProbability: 0.95,  // Requires 95% probability
        maxIterations: 10,
        targetQuality: 0.95
    )

    public static let balanced = AdaptiveHaltingPolicy(
        minConvergenceProbability: 0.75,  // Requires 75% probability
        maxIterations: 5,
        targetQuality: 0.90
    )

    public static let relaxed = AdaptiveHaltingPolicy(
        minConvergenceProbability: 0.60,  // Requires 60% probability
        maxIterations: 3,
        targetQuality: 0.85
    )
}
```

### Integration Example: VerifiedReasoning & Reflexion

**Before** (Arbitrary thresholds):
```swift
// Hardcoded values, no scientific basis
var iterations = 0
let maxIterations = 2  // WHY 2? Arbitrary!

while reliability.score < target && iterations < maxIterations {
    refine(...)
    if newScore <= oldScore { break }  // Primitive check
    iterations += 1
}
```

**After** (Adaptive statistical system):
```swift
// User specifies preference, system computes evidence
let config = TRMConfig(policy: .balanced)  // 75% convergence required

let enhanced = try await trmEnhancement.enhance(
    baseResult: initialResult,
    problem: problem,
    context: context,
    refiner: refiner,
    config: config
)

// Halting based on statistical evidence:
// - Convergence probability from CV, slope, variance
// - Oscillation from binomial distribution
// - Diminishing returns from relative slope
```

**Benefits:**
- **Data-driven halting**: Adapts to each problem's trajectory
- **Scientifically defensible**: CV (ISO 5725), linear regression, statistical tests
- **User empowerment**: Specify confidence requirement, not arbitrary values
- **Quality protection**: Prevents wasted iterations and oscillation

### Completed Integrations
1. ✅ **VerifiedReasoning**: Statistical convergence detection
2. ✅ **Reflexion**: TRM enhancement with adaptive halting
3. ✅ **PlanAndSolve**: TRM enhancement with feedback-driven re-planning
4. ✅ **ChainOfThought**: TRM enhancement with reasoning refinement

**All major reasoning strategies now support adaptive TRM enhancement!**

### Design Principles (3R's Validated)
- **Reliability**: Statistical foundation, defensible decisions
- **Readability**: Clear evidence-based logic vs opaque thresholds
- **Reusability**: ConvergenceEvidence shared across all strategies

### Refinement Protocol
```swift
public protocol RefinableResult {
    var conclusion: String { get }
    var confidence: Double { get }
}

public typealias Refiner<T: RefinableResult> = @Sendable (
    T,        // Previous result
    String,   // Problem
    String    // Context
) async throws -> T
```

### Validation Results (350K+ Samples Tested)

**Test Infrastructure:**
- Parameterizable, scalable validation (tested up to 350K samples)
- 7 realistic reasoning scenarios (typical, stuck, breakthrough, chaotic, regressing, edge cases, excellent)
- Linear scaling O(n), constant memory O(1)

**Accuracy** (5/7 tests passing = 71%):
- ✅ Typical reasoning: 79% convergence detection
- ✅ Breakthrough patterns: 100% no early stopping
- ✅ Regressing trajectories: 100% rejection (negative slope detection)
- ✅ Edge cases: 100% safe handling (no crashes)
- ✅ Already excellent: 100% immediate convergence
- ⚠️ Stuck reasoning: 42% detection (fundamental limit - requires quality thresholds)
- ⚠️ Chaotic patterns: 37% oscillation (acceptable - multi-indicator approach compensates)

**Performance:**
- **54K samples/second** on realistic trajectories
- Scales to billions of samples (5-6 hours for 1B samples)
- No memory accumulation

**Production Readiness:**
- Critical bugs fixed (oscillation, diminishing returns, regression detection)
- 71% accuracy on synthetic patterns (validated with 350K+ samples)
- Ready for cautious deployment with quality thresholds and monitoring
- Multi-criteria approach better than single metrics

**See:** `scripts/comprehensive-validation.swift`, `scripts/README.md`, ADR-008

---

## Related Documentation
- See `NAMING_CONVENTIONS.md` for comprehensive naming standards
- See `Domain/README.md` for entity definitions and ports
- See `Infrastructure/README.md` for port implementations
- See `Composition/README.md` for dependency injection
- See `docs/architecture/overview.md` for full architecture
- See `docs/architecture/PRD_GENERATION_ARCHITECTURE.md` for 9-phase pipeline
- See `ZERO_TOLERANCE_RULES.md` for coding standards
- See `docs/architecture/decisions/` for architectural decisions
