# Composition Layer

## Purpose
The Composition layer is the **dependency injection root** where all pieces come together. It wires Domain, Application, and Infrastructure components into a working system without any business logic of its own.

**Phase 2 (Complete)**: Multi-channel architecture with CLI and REST API working. WebSocket planned for Phase 3.

## Architecture Position
**Composition** is the entry point and orchestration root:
- Depends on **all other layers** (Domain, Application, Infrastructure)
- Creates and configures concrete implementations
- Wires dependencies together
- Provides channel-agnostic use case containers
- Contains ZERO business logic

## Core Responsibility
Answer **how to assemble** the system:
- **How** to create all the adapters?
- **How** to inject dependencies into use cases?
- **How** to configure external services?
- **How** to support multiple presentation channels (CLI, REST, WebSocket)?

The Composition layer is the only place that knows about concrete implementations.

## Multi-Channel Architecture (Phase 2 Complete)

### Overview
```
┌──────────────────────────────────────────────────────┐
│             Presentation Channels                     │
│  ┌────────────┐  ┌──────────┐  ┌──────────────┐    │
│  │  CLI ✅    │  │REST API✅│  │  WebSocket   │    │
│  └──────┬─────┘  └─────┬────┘  └──────┬───────┘    │
└─────────┼───────────────┼──────────────┼────────────┘
          │               │              │
┌─────────┼───────────────┼──────────────┼────────────┐
│         ▼               ▼              ▼            │
│    Composition Layer (Channel-Agnostic)             │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐     │
│  │CLIFactory│    │RESTFactory│   │WSFactory │     │
│  │   ✅     │    │    ✅     │   │(Planned) │     │
│  └─────┬────┘    └─────┬────┘    └────┬─────┘     │
│        │               │               │            │
│        └───────────────┴───────────────┘            │
│                        │                             │
│              ┌─────────▼─────────┐                  │
│              │ApplicationFactory │ ✅               │
│              │(Channel-Agnostic) │                  │
│              └─────────┬─────────┘                  │
│                        │                             │
│              ┌─────────▼─────────┐                  │
│              │ApplicationUseCases│ ✅               │
│              │    (Shared)       │                  │
│              └───────────────────┘                  │
└──────────────────────────────────────────────────────┘
```

### Key Components

**1. Configuration** - Environment-based setup
```swift
public struct Configuration: Sendable {
    public let aiProvider: AIProviderType       // Apple, OpenAI, Anthropic, Gemini
    public let aiAPIKey: String?
    public let aiModel: String?
    public let storageType: StorageType         // Memory, Filesystem, Supabase
    public let storagePath: URL
    public let supabaseURL: String?
    public let supabaseKey: String?

    // Default: Apple Intelligence, in-memory storage
    public static let `default`: Configuration

    // Load from environment variables
    public static func fromEnvironment() -> Configuration
}
```

**2. ApplicationFactory** - Channel-agnostic factory
```swift
public struct ApplicationFactory {
    private let configuration: Configuration

    // Creates fully-wired use cases for any channel
    public func createUseCases() async throws -> ApplicationUseCases
}
```

**3. ApplicationUseCases** - Shared use case container
```swift
public struct ApplicationUseCases {
    // PRD operations
    public let generatePRD: GeneratePRDUseCase
    public let listPRDs: ListPRDsUseCase
    public let getPRD: GetPRDUseCase

    // Session operations (conversational)
    public let createSession: CreateSessionUseCase
    public let continueSession: ContinueSessionUseCase
    public let listSessions: ListSessionsUseCase
    public let getSession: GetSessionUseCase
    public let deleteSession: DeleteSessionUseCase

    // Clarification operations
    public let clarificationOrchestrator: ClarificationOrchestratorUseCase?

    // Codebase operations (optional - requires Supabase configuration)
    public let createCodebase: CreateCodebaseUseCase?
    public let indexCodebase: IndexCodebaseUseCase?
    public let listCodebases: ListCodebasesUseCase?
    public let searchCodebase: SearchCodebaseUseCase?

    // Repository integration (optional - requires OAuth configuration)
    public let connectRepositoryProvider: ConnectRepositoryProviderUseCase?
    public let listUserRepositories: ListUserRepositoriesUseCase?
    public let indexRemoteRepository: IndexRemoteRepositoryUseCase?
    public let disconnectProvider: DisconnectProviderUseCase?
    public let listConnections: ListConnectionsUseCase?
}
```

**4. Channel-Specific Factories** - Thin wrappers
```swift
// CLI Factory
public struct CLIFactory {
    public func createUseCases() async throws -> ApplicationUseCases {
        let config = Configuration.fromEnvironment()
        let factory = ApplicationFactory(configuration: config)
        return try await factory.createUseCases()
    }
}

// REST Factory (Phase 2 Complete)
public struct RESTFactory {
    public func createUseCases() async throws -> ApplicationUseCases {
        let config = Configuration.fromEnvironment()
        let factory = ApplicationFactory(configuration: config)
        return try await factory.createUseCases()
    }
}

// Future: WSFactory follows same pattern
```

## AI Provider Support (October 2025)

### Default Models
- **Apple Intelligence** (default): Apple Foundation Models - On-device, privacy-first
- **OpenAI**: `gpt-5` - Latest reasoning & generation
- **Anthropic**: `claude-sonnet-4-5` - Balanced performance
- **Gemini**: `gemini-2.5-pro` - Google's multimodal flagship

### Configuration Examples
```bash
# Default (Apple Intelligence)
swift run ai-prd generate -t "App" -d "Description"

# OpenAI GPT-5
AI_PROVIDER=openai OPENAI_API_KEY=sk-... swift run ai-prd generate ...

# OpenAI GPT-5 Thinking (extended reasoning)
AI_PROVIDER=openai AI_MODEL=gpt-5-thinking OPENAI_API_KEY=sk-... swift run ...

# Anthropic Claude Sonnet 4.5
AI_PROVIDER=anthropic ANTHROPIC_API_KEY=sk-ant-... swift run ai-prd generate ...

# Anthropic Claude Opus 4.5 (flagship)
AI_PROVIDER=anthropic AI_MODEL=claude-opus-4-5 ANTHROPIC_API_KEY=sk-ant-... swift run ...

# Gemini 2.5 Pro
AI_PROVIDER=gemini GEMINI_API_KEY=... swift run ai-prd generate ...

# Supabase storage
STORAGE_TYPE=supabase SUPABASE_URL=https://... SUPABASE_KEY=... swift run ...
```

### Provider Selection
Configuration automatically detects API keys:
```swift
// Tries OPENAI_API_KEY, then ANTHROPIC_API_KEY, then GEMINI_API_KEY
let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
    ?? ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
```

## Structure

**16 files total:**

```
Composition/
├── Configuration.swift              # Environment-based config
├── StorageType.swift                # Memory, Filesystem, Supabase
├── ConfigurationError.swift         # Configuration errors
├── ApplicationUseCases.swift        # Shared use case container
├── LibraryComposition.swift         # Public composition interface
├── PublicAPI.swift                  # Public API declarations
├── DefaultPRDTemplate.swift         # Default PRD template
├── Factories/                       # 9 factory files
│   ├── ApplicationFactory.swift   # Main channel-agnostic factory
│   ├── AIComponentsFactory.swift  # AI provider components
│   ├── PRDUseCaseFactory.swift    # PRD use case creation
│   ├── CodebaseUseCaseFactory.swift # Codebase use case creation
│   ├── SessionUseCaseFactory.swift  # Session use case creation
│   ├── IntegrationFactory.swift   # Repository integration factory
│   ├── RAGFactory.swift           # RAG infrastructure factory
│   ├── RepositoryFactory.swift    # Repository adapters factory
│   └── FactoryDependencies.swift  # Internal dependency container
└── README.md
```

## Intelligence Enhancement (Phase 12 Complete)

### RAGFactory - Specialized RAG Component Factory

**Purpose:** Create RAG infrastructure components (HybridSearch, Embeddings, FullTextSearch) with proper dependency management.

**Why Extracted:** ApplicationFactory was 310 lines (violated Zero Tolerance 300-line limit). RAGFactory extraction follows Single Responsibility Principle.

```swift
// RAGFactory.swift (69 lines)
struct RAGFactory {
    private let configuration: Configuration

    // Creates HybridSearchService with all components
    func createHybridSearchService() async -> HybridSearchService? {
        guard let repository = await createCodebaseRepository(),
              let embeddings = await createEmbeddingGenerator(),
              let fullText = await createFullTextSearch() else {
            return nil  // Graceful degradation
        }

        return HybridSearchService(
            codebaseRepository: repository,
            embeddingGenerator: embeddings,
            fullTextSearch: fullText
        )
    }

    // Component factories
    func createCodebaseRepository() async -> CodebaseRepositoryPort?
    func createEmbeddingGenerator() async -> EmbeddingGeneratorPort?
    func createFullTextSearch() async -> FullTextSearchPort?
}
```

**RAG Components:**
- **HybridSearchService**: Vector + Keyword search with RRF fusion
- **NaturalLanguageEmbeddings**: Apple's NaturalLanguage framework (iOS 16+)
- **SupabaseCodebaseRepository**: Code chunk persistence
- **PostgreSQLFullTextSearch**: BM25 keyword search (Supabase RPC)

**Graceful Degradation:**
```swift
// Supabase configured: Full RAG
let hybridSearch = await ragFactory.createHybridSearchService()
// → HybridSearchService with all components

// Memory/filesystem storage: No RAG
let hybridSearch = await ragFactory.createHybridSearchService()
// → nil (graceful)

// iOS <16: No embeddings
let hybridSearch = await ragFactory.createHybridSearchService()
// → nil (NaturalLanguage unavailable)
```

### EnrichedContextBuilder - Intelligence Integration

**Purpose:** Orchestrate RAG + Reasoning for context-aware PRD generation.

**ApplicationFactory Wiring (Phase 12):**
```swift
public func createEnrichedContextBuilder() async throws -> EnrichedContextBuilder? {
    // Stage 1: Reasoning infrastructure (always available)
    let thinkingOrchestrator = try await createThinkingOrchestrator()

    // Stage 2: RAG infrastructure (when Supabase configured)
    let ragFactory = createRAGFactory()
    let hybridSearch = await ragFactory.createHybridSearchService()

    return EnrichedContextBuilder(
        hybridSearch: hybridSearch,               // nil if no Supabase
        reasoningOrchestrator: thinkingOrchestrator  // always present
    )
}
```

**Intelligence Contexts:**
- **RAG Context**: Codebase patterns, existing architecture (when available)
- **Reasoning Context**: Logical analysis, requirement planning (always available)
- **Multi-Modal Aggregation**: Unified intelligence context with XML markup

**Usage in PRD Generation:**
```swift
// GeneratePRDUseCase
let enrichedContext = try await enrichedContextBuilder?.buildContext(
    request: request,
    codebaseId: request.codebaseId
)

// Inject into prompts (XML-formatted)
let prompt = promptBuilder.buildSectionPrompt(
    section: sectionType,
    context: sectionContext,
    enrichedContext: enrichedContext  // RAG + Reasoning
)
```

**See:** ADR-013 for full architecture decision details.

## Design Principles

### 1. Channel-Agnostic Core
All channels share the same `ApplicationFactory`:
```swift
// ✅ GOOD: Shared factory
public struct ApplicationFactory {
    private let configuration: Configuration

    public func createUseCases() async throws -> ApplicationUseCases {
        // Creates repositories based on configuration
        let dependencies = try await createDependencies()

        // Wires use cases with injected dependencies
        return try await wireUseCases(dependencies: dependencies)
    }
}

// CLI uses it
public struct CLIFactory {
    public func createUseCases() async throws -> ApplicationUseCases {
        let config = Configuration.fromEnvironment()
        let factory = ApplicationFactory(configuration: config)
        return try await factory.createUseCases()
    }
}

// Future: REST API uses same factory
public struct RESTFactory {
    public func createUseCases(config: Configuration) async throws -> ApplicationUseCases {
        let factory = ApplicationFactory(configuration: config)
        return try await factory.createUseCases()
    }
}
```

### 2. Configuration-Driven Setup
All behavior controlled by configuration:
```swift
// ✅ GOOD: Configuration drives everything
private func createAIProvider() throws -> AIProviderPort {
    let providerConfig = AIProviderConfiguration(
        type: configuration.aiProvider,     // From environment
        apiKey: configuration.aiAPIKey,     // From environment
        model: configuration.aiModel        // Optional override
    )

    let factory = AIProviderFactory()
    return try factory.createProvider(from: providerConfig)
}

private func createPRDRepository() async throws -> PRDRepositoryPort {
    switch configuration.storageType {
    case .memory:
        return InMemoryPRDRepository()
    case .filesystem:
        // FilesystemPRDRepository not yet implemented, using in-memory
        return InMemoryPRDRepository()
    case .supabase:
        let databaseClient = try createSupabaseDatabaseClient()
        return SupabasePRDRepository(databaseClient: databaseClient)
    }
}
```

### 3. Dependency Injection
All dependencies injected via constructors:
```swift
// ✅ GOOD: Constructor injection
let generatePRD = GeneratePRDUseCase(
    aiProvider: dependencies.aiProvider,
    prdRepository: dependencies.prdRepository,
    templateRepository: dependencies.templateRepository,
    codebaseRepository: nil,        // Optional: RAG feature
    embeddingGenerator: nil         // Optional: RAG feature
)

// ❌ BAD: Use case creating dependencies
public struct GeneratePRDUseCase {
    private let aiProvider = MockAIProvider()  // ❌ Never do this
}
```

### 4. Factory Delegation
Channel factories delegate to `ApplicationFactory`:
```swift
// ✅ GOOD: Thin wrapper delegates to shared factory
public struct CLIFactory {
    private let appFactory: ApplicationFactory

    public init() {
        let configuration = Configuration.fromEnvironment()
        self.appFactory = ApplicationFactory(configuration: configuration)
    }

    public func createUseCases() async throws -> ApplicationUseCases {
        return try await appFactory.createUseCases()  // Delegate
    }
}

// ❌ BAD: Duplicating factory logic
public struct CLIFactory {
    public func createUseCases() async throws -> CLIUseCases {
        // ❌ Reimplementing dependency creation
        let provider = MockAIProvider()
        let repository = InMemoryPRDRepository()
        // ...
    }
}
```

## Integration Points

### Consumes From All Layers
- **Domain**: Entities, Ports, Value Objects
- **Application**: Use Cases, Services
- **Infrastructure**: Concrete Implementations (Providers, Repositories)

### Provides To Presentation Channels
- **CLI** ✅: CommandLineInterface uses ApplicationUseCases
- **REST API** ✅: SessionController and PRDController use ApplicationUseCases
- **WebSocket** (Planned): Handlers will use ApplicationUseCases

## Adding New Channels

To add a new presentation channel:

**1. Create channel-specific factory:**
```swift
public struct RESTFactory {
    private let appFactory: ApplicationFactory

    public init(configuration: Configuration) {
        self.appFactory = ApplicationFactory(configuration: configuration)
    }

    public func createUseCases() async throws -> ApplicationUseCases {
        return try await appFactory.createUseCases()
    }
}
```

**2. Use ApplicationUseCases in channel:**
```swift
public struct SessionController {
    private let useCases: ApplicationUseCases

    public init(useCases: ApplicationUseCases) {
        self.useCases = useCases
    }

    public func createSession(req: Request) async throws -> Response {
        let session = try await useCases.createSession.execute()
        return Response(session: session.toDTO())
    }
}
```

**3. Wire in server startup:**
```swift
let config = Configuration.fromEnvironment()
let factory = RESTFactory(configuration: config)
let useCases = try await factory.createUseCases()

// Inject into controllers
let sessionController = SessionController(useCases: useCases)
app.post("sessions", use: sessionController.createSession)
```

## Environment Variables

### AI Provider Configuration
```bash
# Provider selection (default: apple)
AI_PROVIDER=apple           # or: openai, anthropic, gemini, claude, gpt, google, foundation

# API Keys (auto-detected)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=...

# Model override (optional)
AI_MODEL=gpt-5-thinking     # Override default model
AI_MODEL=claude-opus-4-5    # Anthropic flagship
AI_MODEL=gemini-2.5-pro     # Gemini latest
```

### Storage Configuration
```bash
# Storage type (default: memory)
STORAGE_TYPE=memory         # or: filesystem, supabase

# Filesystem
STORAGE_PATH=/path/to/data

# Supabase
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_KEY=your-anon-key
```

## Testing Strategy

### Configuration Tests
```swift
func testDefaultConfiguration() {
    let config = Configuration.default

    XCTAssertEqual(config.aiProvider, .appleFoundationModels)
    XCTAssertEqual(config.storageType, .memory)
    XCTAssertNil(config.aiAPIKey)
}

func testEnvironmentConfiguration() {
    setenv("AI_PROVIDER", "anthropic", 1)
    setenv("ANTHROPIC_API_KEY", "sk-ant-test", 1)
    setenv("STORAGE_TYPE", "supabase", 1)

    let config = Configuration.fromEnvironment()

    XCTAssertEqual(config.aiProvider, .anthropic)
    XCTAssertEqual(config.aiAPIKey, "sk-ant-test")
    XCTAssertEqual(config.storageType, .supabase)
}
```

### Factory Tests
```swift
func testApplicationFactoryCreatesUseCases() async throws {
    let config = Configuration.default
    let factory = ApplicationFactory(configuration: config)

    let useCases = try await factory.createUseCases()

    XCTAssertNotNil(useCases.generatePRD)
    XCTAssertNotNil(useCases.createSession)
    XCTAssertNotNil(useCases.listSessions)
}

func testCLIFactoryDelegatesToApplicationFactory() async throws {
    let cliFactory = CLIFactory()

    let useCases = try await cliFactory.createUseCases()

    // Verifies delegation works
    XCTAssertNotNil(useCases.generatePRD)
}
```

## Common Violations to Avoid

### ❌ Business Logic in Composition
```swift
// BAD
public struct ApplicationFactory {
    public func createUseCases() async throws -> ApplicationUseCases {
        // ❌ Validation is domain/application concern
        guard !configuration.aiAPIKey.isEmpty else {
            throw Error.invalidAPIKey
        }
    }
}
```

### ❌ Duplicate Factory Logic
```swift
// BAD: Reimplementing in each channel
public struct CLIFactory {
    public func createUseCases() async throws -> ApplicationUseCases {
        // ❌ Duplicating ApplicationFactory logic
        let provider = MockAIProvider()
        let repository = InMemoryPRDRepository()
        let generatePRD = GeneratePRDUseCase(...)
        // ...
    }
}
```

### ❌ Channel-Specific Use Case Containers
```swift
// BAD: Different containers for each channel
public struct CLIUseCases { ... }          // ❌
public struct RESTUseCases { ... }         // ❌
public struct WebSocketUseCases { ... }    // ❌

// GOOD: Single shared container
public struct ApplicationUseCases { ... }  // ✅
```

## Completed Phases

### ✅ Phase 1: Multi-Channel Foundation (2025-10-12)
- Created `ApplicationFactory` (channel-agnostic)
- Created `Configuration` system (environment-based)
- Renamed `CLIUseCases` → `ApplicationUseCases`
- Updated `CLIFactory` to delegate to `ApplicationFactory`
- 4 AI providers integrated (Apple, OpenAI, Anthropic, Gemini)

### ✅ Phase 2: REST API (2025-10-12)
- Added `RESTFactory` using `ApplicationFactory`
- Created `SessionController` and `PRDController` consuming `ApplicationUseCases`
- Mapped HTTP routes to use cases (9 endpoints)
- Added Vapor 4.117.0 dependency
- **Zero changes needed to ApplicationFactory or ApplicationUseCases**

## Future Phases

### Phase 3: WebSocket + Production Deployment (Next)
- Add `WSFactory` using `ApplicationFactory`
- Create WebSocket handlers consuming `ApplicationUseCases`
- Stream real-time PRD generation events
- Docker containerization
- Production middleware (CORS, logging, errors, rate limiting)
- **No changes needed to ApplicationFactory or ApplicationUseCases**

### Phase 4: API Documentation & Frontend Integration
- OpenAPI/Swagger documentation
- Frontend integration guides
- JavaScript/TypeScript examples

### Phase 5: Frontend Example Application (Optional)
- Next.js example with REST + WebSocket
- Reference implementation for frontend developers

## Related Documentation
- See `NAMING_CONVENTIONS.md` for comprehensive naming standards
- See `Domain/README.md` for entity definitions and ports
- See `Application/README.md` for use cases
- See `Infrastructure/README.md` for implementations
- See `docs/architecture/overview.md` for full architecture
- See `docs/architecture/decisions/010-multi-channel-communication.md` for ADR
- See `ZERO_TOLERANCE_RULES.md` for coding standards
