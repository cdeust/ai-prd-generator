# Domain Layer (Business Layer Context)

> **Architecture Context:** This layer is part of the **Business Layer** (`library/`) in our Layered Isolation Architecture. Microservices access this layer via the `LibraryComposition` interface. See [layered-isolation-architecture.md](../../../docs/architecture/layered-isolation-architecture.md) for complete system architecture.

## Purpose
The Domain layer contains the core business logic, entities, and rules for AI-driven PRD generation. It is the heart of the system, completely independent of any frameworks, databases, or external services.

## Architecture Position

```
MICROSERVICES (backend/Sources/Services/)
    ↓ Call LibraryComposition interface
BUSINESS LAYER (library/)
    ├── Composition/     ← Public interface
    ├── Application/     ← Orchestrates Domain
    └── Domain/          ← YOU ARE HERE (pure business logic)
```

**Domain Layer Characteristics:**
- **ZERO framework dependencies** (no Vapor, no Supabase, no HTTP)
- Only imports Foundation for basic types (UUID, Date, String, etc.)
- Defines **ports** (protocols) that Infrastructure/Microservices implement
- Contains pure business logic and domain entities
- Never directly called by microservices (accessed via Application layer through LibraryComposition)

## Core Responsibility
Encode the fundamental concepts and rules of PRD generation:
- **What** is a PRD document and its components?
- **What** rules govern PRD completeness and validity?
- **How** should structured reasoning work?
- **What** interfaces (ports) do we need from external systems?

## Naming Conventions

> **See `NAMING_CONVENTIONS.md` for comprehensive standards**

**Domain Layer Patterns:**
- **Entities**: `{BusinessConcept}` (PRDDocument, Mockup, CodeSymbol)
- **Value Objects**: `{Concept}` or `{Property}` (AIProvider, ChunkType, Platform)
- **Ports**: `{Domain}{Action}Protocol` or `{Concept}Port` (PRDRepositoryProtocol, CodeParserPort)
- **Errors**: `{Domain}Error` (PRDError, CodebaseError)
- **File Naming**: One structure per file, PascalCase (PRDDocument.swift)

## Structure

```
Domain/
├── Entities/                    # Domain objects with business logic (18 subdirectories, 265 total files)
│   ├── PRDDocument/            # PRD entities
│   │   ├── PRDDocument.swift
│   │   ├── PRDSection.swift
│   │   ├── DocumentMetadata.swift
│   │   └── ...
│   ├── Thinking/               # Reasoning entities (50+ files)
│   │   ├── ThoughtChain.swift
│   │   ├── Thought.swift
│   │   ├── ReasoningHop.swift
│   │   ├── ReasoningNode.swift
│   │   ├── TreeNode.swift
│   │   ├── GraphNode.swift
│   │   ├── TRMConfig.swift
│   │   ├── TRMIteration.swift
│   │   ├── ConvergenceEvidence.swift
│   │   ├── AdaptiveHaltingPolicy.swift
│   │   └── ... (Adaptive TRM, ReAct, Reflexion, etc.)
│   ├── ProfessionalAnalysis/   # Analysis entities
│   │   ├── ProfessionalAnalysis.swift
│   │   ├── TechnicalChallenge.swift
│   │   ├── ConflictDetection.swift
│   │   └── ...
│   ├── Codebase/               # Code entities
│   │   ├── Codebase.swift
│   │   ├── CodeFile.swift
│   │   ├── CodeSymbol.swift
│   │   ├── ParsedCodeChunk.swift
│   │   ├── IndexedProject.swift
│   │   └── ...
│   ├── Mockup/                 # UI mockup entities
│   │   ├── Mockup.swift
│   │   ├── MockupAnalysisResult.swift
│   │   ├── UIComponent.swift
│   │   ├── InferredDataRequirement.swift
│   │   ├── Interaction.swift
│   │   └── ...
│   ├── VectorSearch/           # RAG entities
│   │   ├── CodeChunk.swift
│   │   ├── CodeEmbedding.swift
│   │   └── ...
│   ├── RAG/                    # RAG context entities
│   │   ├── ContextNode.swift
│   │   ├── ContextEdge.swift
│   │   └── ...
│   ├── OpenAPI/                # OpenAPI entities
│   │   ├── OpenAPISpecification.swift
│   │   └── ...
│   ├── Testing/                # Test entities
│   │   ├── TestSuite.swift
│   │   └── ...
│   ├── PRDTemplate/            # Template entities
│   │   └── PRDTemplate.swift
│   ├── Chunking/               # Chunking entities (Phase 2)
│   │   ├── TextChunk.swift
│   │   └── HierarchicalChunk.swift
│   ├── Compression/            # Compression entities (Phase 2)
│   │   └── CompressedContext.swift
│   ├── GapDetection/           # Gap detection entities (Phase 4)
│   │   ├── InformationGap.swift
│   │   └── ResolutionAttempt.swift
│   ├── Clarification/          # Clarification entities
│   │   ├── ClarificationQuestion.swift
│   │   ├── ClarificationSession.swift
│   │   └── GapAnalysisResult.swift
│   ├── Integration/            # Repository integration entities
│   │   ├── RepositoryConnection.swift
│   │   ├── RemoteRepository.swift
│   │   ├── OAuthTokenResponse.swift
│   │   ├── ProviderUserInfo.swift
│   │   └── FileTreeNode.swift
│   ├── Configuration/          # Configuration entities
│   │   └── ...
│   ├── Session/                # Session entities
│   │   └── ...
│   └── Prompts/                # Prompt template entities
│       └── ...
├── Ports/                      # Interfaces for external dependencies (28 ports)
│   ├── AIProviderPort.swift        # AI model integration
│   ├── PRDRepositoryPort.swift     # PRD persistence
│   ├── PRDTemplateRepositoryPort.swift  # Template management
│   ├── PRDCodebaseLinkPort.swift   # PRD-codebase linkage
│   ├── CodeParserPort.swift        # Code parsing
│   ├── CodebaseRepositoryPort.swift     # Codebase persistence
│   ├── EmbeddingGeneratorPort.swift     # Vector embeddings
│   ├── EmbeddingStoragePort.swift       # Vector storage
│   ├── MockupAnalysisPort.swift    # Mockup image analysis
│   ├── MockupRepositoryPort.swift  # Mockup persistence
│   ├── ThinkingPort.swift          # Advanced reasoning
│   ├── UserInteractionPort.swift   # User prompts/clarifications
│   ├── VectorSearchPort.swift      # Vector similarity search
│   ├── FullTextSearchPort.swift    # Keyword/BM25 search
│   ├── VisionAnalysisPort.swift    # Vision model integration
│   ├── TokenizerPort.swift         # Token counting
│   ├── ChunkerPort.swift           # Text/code chunking
│   ├── ContextCompressorPort.swift # Context compression
│   ├── FewShotPromptPort.swift     # Few-shot learning
│   ├── GapDetectionPort.swift      # Gap detection
│   ├── HashingPort.swift           # Content hashing
│   ├── DebugLoggerPort.swift       # Debug logging
│   ├── OrchestrationPort.swift     # Workflow orchestration
│   ├── OAuthClientPort.swift       # OAuth integration
│   ├── RepositoryConnectionPort.swift   # Repo connection mgmt
│   ├── RepositoryFetcherPort.swift      # Remote repo fetching
│   ├── SessionRepositoryPort.swift      # Session persistence
│   └── Supabase/               # Supabase-specific ports
│       ├── SupabaseDatabasePort.swift
│       ├── SupabaseStoragePort.swift
│       ├── SupabaseRealtimePort.swift
│       └── SupabaseClientPort.swift
├── Prompts/                    # Prompt templates (pure strings)
│   └── PRD/                    # PRD generation prompts
│       ├── SystemPrompt.swift
│       ├── OverviewTemplate.swift
│       ├── UserStoriesTemplate.swift
│       ├── DataModelTemplate.swift
│       ├── FeaturesTemplate.swift
│       ├── APISpecTemplate.swift
│       ├── TestSpecTemplate.swift
│       ├── ConstraintsTemplate.swift
│       ├── ValidationTemplate.swift
│       ├── RoadmapTemplate.swift
│       └── AnalysisTemplates.swift
├── ValueObjects/               # Immutable value types
│   ├── SectionType.swift
│   ├── TemplateSectionConfig.swift
│   ├── Priority.swift
│   ├── ChunkType.swift
│   ├── SymbolType.swift
│   ├── ChallengeCategory.swift
│   ├── ConflictType.swift
│   ├── Platform.swift
│   ├── ArchitecturePattern.swift
│   ├── Tokenization/           # Token management (Phase 2)
│   │   ├── TokenizerProvider.swift
│   │   ├── TokenBudget.swift
│   │   ├── PhaseBudget.swift
│   │   ├── BudgetStrategy.swift
│   │   ├── BudgetPriority.swift
│   │   ├── GenerationPhase.swift
│   │   └── ModelType.swift
│   ├── FewShotLearning/        # Few-shot learning (Phase 2)
│   │   └── FewShotPromptExample.swift
│   ├── Chunking/               # Chunking strategies (Phase 2)
│   │   ├── ChunkingStrategy.swift
│   │   └── ChunkMetadata.swift
│   ├── Compression/            # Compression (Phase 2)
│   │   ├── CompressionTechnique.swift
│   │   └── CompressionMetadata.swift
│   ├── GapDetection/           # Gap detection (Phase 4)
│   │   ├── GapCategory.swift
│   │   ├── GapPriority.swift
│   │   ├── ResolutionStrategy.swift
│   │   ├── ResolutionConfidence.swift
│   │   ├── GapDetectionContext.swift
│   │   ├── CodebaseGapContext.swift
│   │   ├── GapContext.swift
│   │   ├── GapStatus.swift
│   │   ├── ResolutionResult.swift
│   │   ├── ConfidenceLevel.swift
│   │   ├── EvidenceSource.swift
│   │   ├── EvidenceType.swift
│   │   └── StrategyCost.swift
│   ├── Errors/                 # Error value objects
│   │   ├── CodeParsingError.swift
│   │   ├── EmbeddingError.swift
│   │   ├── RepositoryError.swift
│   │   ├── ValidationError.swift
│   │   ├── TokenizationError.swift
│   │   ├── ChunkingError.swift
│   │   ├── CompressionError.swift
│   │   └── GapResolutionError.swift
│   └── ...
└── Public/                     # Public SDK API types
    ├── AIPRDConfiguration.swift
    ├── AIPRDClientFactory.swift
    └── DTOs/                   # Public data transfer objects
        ├── GeneratePRDRequest.swift
        ├── MockupInput.swift
        ├── PRDResponse.swift
        ├── IndexCodebaseRequest.swift
        ├── SearchCodebaseRequest.swift
        └── ...
```

**Entity Organization Pattern:**
- **Complex entities (multiple related structures)** → Subdirectory with one file per structure
- **Simple entities (single structure)** → Single file in Entities/
- **Rationale:** See ADR 002 for subdirectory organization decision

## Design Principles

### 1. Framework Independence
The Domain layer must NOT import:
- ❌ UIKit / AppKit / SwiftUI
- ❌ Vapor / Networking frameworks
- ❌ Database libraries
- ❌ Any Infrastructure code

Only Foundation basics are allowed:
- ✅ UUID, Date, String, Int, Double
- ✅ Codable (for serialization contracts)
- ✅ Sendable (for concurrency safety)

### 2. Business Logic Ownership
All business rules live here:
```swift
// ✅ GOOD: Business logic in domain
public struct PRDDocument {
    public func isComplete() -> Bool {
        hasRequiredSections() && allSectionsValid()
    }
}

// ❌ BAD: Business logic in infrastructure
public class PRDRepository {
    func save(_ doc: PRDDocument) {
        if doc.sections.count < 3 { ... }  // ❌ Business rule in infrastructure
    }
}
```

### 3. Dependency Inversion
Domain **defines** the interfaces (ports) it needs:
```swift
// Domain defines what it needs
public protocol AIProviderPort {
    func generateText(prompt: String) async throws -> String
}

// Infrastructure implements it
public struct OpenAIProvider: AIProviderPort {
    func generateText(prompt: String) async throws -> String {
        // Implementation details
    }
}
```

### 4. Immutability
Entities are value types (structs) with immutable properties:
```swift
// ✅ GOOD: Immutable entity
public struct PRDDocument: Sendable {
    public let id: UUID
    public let title: String
    public let sections: [PRDSection]
}

// ❌ BAD: Mutable entity
public class PRDDocument {
    public var title: String  // ❌ Mutable
    public var sections: [PRDSection]  // ❌ Mutable
}
```

## Key Concepts

### Entities
Domain objects with identity and business logic:
- **PRDDocument**: The main product requirements document
- **PRDTemplate**: Reusable PRD structure with section configuration
- **ThoughtChain**: Structured AI reasoning process
- **Codebase**: Indexed codebase for context
- **ProfessionalAnalysis**: Quality and complexity assessment
- **InformationGap** (Phase 4): Detected missing information in PRD generation
- **ResolutionAttempt** (Phase 4): Attempts to resolve information gaps

Entities have:
- Unique identity (UUID)
- Business logic methods
- Validation rules
- Invariants they maintain

### Value Objects
Immutable types representing domain concepts:
- **SectionType**: Categories of PRD sections
- **Priority**: Requirement priority levels
- **ProgrammingLanguage**: Supported languages
- **IndexingStatus**: Codebase indexing states

Value objects:
- Have no identity (equality by value)
- Are immutable
- Encapsulate domain concepts
- Are reusable across entities

### Composable Reasoning Architecture with Adaptive TRM (Phase 4.6)

The system supports composable AI reasoning strategies enhanced with TRM (Tiny Recursion Model) that uses **statistical analysis** instead of arbitrary thresholds.

**Base Strategies** (Value Objects):
- **ChainOfThought**: Sequential reasoning steps
- **Reflexion**: Self-reflection and iterative improvement
- **PlanAndSolve**: Planning before execution
- **VerifiedReasoning**: Multi-hop reasoning with verification

**Adaptive TRM Enhancement** (Value Objects):
- **ConvergenceEvidence**: Statistical analysis of trajectory data
  - Coefficient of Variation (σ/μ) - relative variability
  - Linear regression - trend slope analysis
  - Variance ratio - statistical significance testing
  - Oscillation detection - binomial distribution
  - Convergence probability - weighted multi-indicator (0-1)

- **AdaptiveHaltingPolicy**: User preference, not arbitrary thresholds
  - User specifies confidence requirement (0.5-0.99)
  - System computes convergence from evidence
  - Statistical comparison: evidence probability ≥ user requirement
  - Presets: strict (95%), balanced (75%), relaxed (60%)

**Composition Pattern**:
```swift
// Standalone strategy
.reflexion

// Enhanced strategy with adaptive TRM
.enhanced(
    baseStrategy: .reflexion,
    enhancement: .trmRefinement(
        config: TRMConfig(policy: .balanced)
    )
)
```

**Statistical Foundation**:
- All metrics computed from observed trajectory (no hardcoded thresholds)
- Convergence probability based on CV, slope, variance ratio
- Oscillation detection using binomial distribution (count > μ + σ)
- Diminishing returns via relative slope (< 1% of mean)

**Benefits:**
- **Data-driven**: Adapts to each problem's trajectory characteristics
- **Scientifically grounded**: ISO-standard CV, linear regression, statistical tests
- **User control**: Specify confidence requirement, not arbitrary values
- **Defensible**: Every decision backed by mathematical analysis

**See:** ADR-008 for architectural details and `ConvergenceEvidence.swift` / `AdaptiveHaltingPolicy.swift` for implementation

### Ports (Interfaces)
Contracts that outer layers must fulfill:
- **AIProviderPort**: Text generation capabilities
- **PRDRepositoryPort**: PRD persistence
- **PRDTemplateRepositoryPort**: Template storage and retrieval
- **CodebaseRepositoryPort**: Codebase storage and search
- **EmbeddingGeneratorPort**: Vector embeddings for RAG
- **GapDetectionPort** (Phase 4): Gap detection and categorization

Ports define:
- Required capabilities
- Method signatures
- Error cases
- Behavioral contracts

### Prompts
Pure string templates for AI interaction:
- System instructions
- Section generation prompts
- Analysis templates
- Validation criteria

Prompts are:
- Pure strings with placeholders
- Domain knowledge encoded
- Framework-agnostic
- Version-controlled

## Integration Points

### Consumed By
- **Application Layer**: Uses entities and depends on ports
- **Infrastructure Layer**: Implements ports, uses entities for DTOs
- **Composition Layer**: Wires everything together

### Provides To Others
- Entity definitions (PRDDocument, ThoughtChain, etc.)
- Port contracts (interfaces for external services)
- Value objects (shared types)
- Business rules and validation logic

## Design Constraints

### Must
- ✅ Contain only pure business logic
- ✅ Use only Foundation basics
- ✅ Define all external dependencies as ports
- ✅ Use immutable value types
- ✅ Be testable without any infrastructure

### Must Not
- ❌ Import any infrastructure code
- ❌ Know about HTTP, databases, or file systems
- ❌ Depend on any framework beyond Foundation
- ❌ Contain UI logic or presentation concerns
- ❌ Have mutable shared state

## Testing Strategy

Domain entities are tested in **pure unit tests**:
- No network calls
- No database access
- No file system operations
- Only logic and rules validation

Example:
```swift
func testPRDCompleteness() {
    let document = PRDDocument(
        title: "Test",
        sections: [
            PRDSection(type: .overview, ...),
            PRDSection(type: .requirements, ...)
        ],
        metadata: ...
    )

    XCTAssertTrue(document.isComplete())
}
```

## Common Violations to Avoid

### ❌ Framework Coupling
```swift
// BAD: Domain importing infrastructure
import Vapor  // ❌

public struct PRDDocument {
    func save(to db: Database) { ... }  // ❌
}
```

### ❌ Business Logic Leak
```swift
// BAD: Business rule in application/infrastructure
public class GeneratePRDUseCase {
    func execute() {
        if sections.count < 3 {  // ❌ Should be in domain
            throw Error.incomplete
        }
    }
}
```

### ❌ Concrete Dependencies
```swift
// BAD: Domain depending on concrete implementation
public struct ThoughtChain {
    private let openAI = OpenAIProvider()  // ❌ Concrete dependency
}
```

## Adding New Domain Concepts

When adding new entities/concepts:

1. **Ask**: Is this a core business concept?
2. **Define**: Entity or Value Object?
3. **Rules**: What invariants must it maintain?
4. **Ports**: What external capabilities does it need?
5. **Place**: Proper subdirectory (Entities/, ValueObjects/, Ports/)
6. **Test**: Pure unit tests for all business logic

## Related Documentation
- See `NAMING_CONVENTIONS.md` for comprehensive naming standards
- See `docs/architecture/overview.md` for full system architecture
- See `ZERO_TOLERANCE_RULES.md` for coding standards
- See `docs/architecture/decisions/` for architectural decisions
- See `Application/README.md` for use case orchestration
- See `Infrastructure/README.md` for port implementations
