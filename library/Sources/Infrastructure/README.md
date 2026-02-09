# Infrastructure Layer (Business Layer Context)

> **Architecture Context:** This layer is part of the **Business Layer** (`library/`) in our Layered Isolation Architecture. It provides adapters that microservices can use, but infrastructure implementations can ALSO live directly in microservices. See [layered-isolation-architecture.md](../../../docs/architecture/layered-isolation-architecture.md) for complete system architecture.

## Purpose
The Infrastructure layer provides **concrete implementations** of the ports (interfaces) defined by the Domain layer. It handles external interactions like databases, APIs, file systems, AI providers, and third-party services.

## Architecture Position

```
MICROSERVICES (backend/Sources/Services/)
    ↓ May have their own infrastructure adapters
    ↓ OR use shared adapters from library/Infrastructure
BUSINESS LAYER (library/)
    ├── Composition/     ← Wires dependencies
    ├── Application/     ← Use cases
    ├── Domain/          ← Defines ports
    └── Infrastructure/  ← YOU ARE HERE (port implementations)
```

**Infrastructure Layer Characteristics:**
- Depends on **Domain** (to implement ports)
- Depends on **Application** (to know use case contracts)
- **CAN import frameworks** (Supabase, CryptoKit, etc.)
- Implements external integrations
- Shared by both library compositions AND microservices
- Not all infrastructure must be here - microservices can have their own adapters

## Core Responsibility
Implement **how** we interact with external systems:
- **How** do we call OpenAI/Claude/Gemini APIs?
- **How** do we store PRDs in Supabase?
- **How** do we parse Swift/TypeScript code?
- **How** do we generate vector embeddings?

The Infrastructure layer translates between external systems and our domain.

## Naming Conventions

> **See `NAMING_CONVENTIONS.md` for comprehensive standards**

**Infrastructure Layer Patterns:**
- **Implementations**: `{Technology}{Domain}{Type}` (HTTPPRDRepository, OpenAIProvider)
- **Parsers**: `{Language}CodeParser` (SwiftCodeParser, TypeScriptCodeParser)
- **Helpers**: `{Language}{Purpose}` (SwiftSymbolExtractor, SwiftComplexityCalculator)
- **Adapters**: `{Technology}{Domain}Adapter` (SupabaseAdapter)
- **Clients**: `{Technology}Client` (SupabaseClient, HTTPClient)
- **File Naming**: One structure per file, PascalCase (OpenAIProvider.swift)

## Structure

**220 files across 21 directories:**

```
Infrastructure/
├── AIProviders/              # AI service implementations (37 files)
│   ├── OpenAIProvider.swift
│   ├── AnthropicProvider.swift
│   ├── GeminiProvider.swift
│   ├── AppleFoundationModelsProvider.swift
│   ├── AIProviderFactory.swift
│   ├── AIProviderConfiguration.swift
│   ├── AIProviderType.swift
│   ├── OpenAI/              # OpenAI DTOs
│   │   ├── OpenAIChatCompletionRequest.swift
│   │   ├── OpenAIChatCompletionResponse.swift
│   │   ├── OpenAIChatMessage.swift
│   │   ├── OpenAIStreamChunk.swift
│   │   └── OpenAIErrorResponse.swift
│   ├── Anthropic/           # Anthropic DTOs
│   │   ├── AnthropicMessageRequest.swift
│   │   ├── AnthropicMessageResponse.swift
│   │   ├── AnthropicMessage.swift
│   │   ├── AnthropicStreamChunk.swift
│   │   └── AnthropicErrorResponse.swift
│   └── Gemini/              # Gemini DTOs
│       ├── GeminiGenerateContentRequest.swift
│       ├── GeminiGenerateContentResponse.swift
│       ├── GeminiContent.swift
│       ├── GeminiStreamChunk.swift
│       └── GeminiErrorResponse.swift
├── Vision/                   # Vision model implementations (75 files)
│   ├── Anthropic/           # Claude vision analyzer
│   ├── Apple/               # Apple Intelligence vision
│   ├── Gemini/              # Gemini vision analyzer
│   ├── OpenAI/              # GPT-4 Vision analyzer
│   ├── Shared/              # Shared vision DTOs
│   ├── Helpers/             # Vision processing utilities
│   ├── VisionAnalyzerFactory.swift
│   ├── AnthropicVisionAnalyzer.swift
│   ├── AppleVisionAnalyzer.swift
│   ├── GeminiVisionAnalyzer.swift
│   ├── OpenAIVisionAnalyzer.swift
│   └── MockVisionAnalyzer.swift
├── Repositories/             # Data persistence implementations (18 files)
│   ├── SupabasePRDRepository.swift
│   ├── SupabaseCodebaseRepository.swift
│   ├── HTTPCodebaseRepository.swift
│   ├── SupabaseSessionRepository.swift
│   ├── SupabaseRepositoryConnectionRepository.swift
│   └── ... (various repository implementations)
├── Supabase/                 # Supabase integration (32 files)
│   ├── SupabaseClient.swift
│   ├── DTOs/                # Supabase DTOs
│   │   ├── SupabasePRDRequestDTO.swift
│   │   ├── SupabasePRDDocumentDTO.swift
│   │   ├── SupabaseCodebaseDTO.swift
│   │   ├── SupabaseSessionDTO.swift
│   │   └── ... (various DTOs)
│   └── Mappers/             # DTO mappers
│       ├── SupabasePRDDocumentMapper.swift
│       ├── SupabaseCodebaseMapper.swift
│       └── ... (various mappers)
├── OAuth/                    # OAuth client implementations (1 file)
│   └── StandardOAuthClient.swift  # Generic OAuth 2.0 client
├── RepositoryFetchers/       # Remote repository fetching (2 files)
│   ├── GitHubRepositoryFetcher.swift   # GitHub API integration
│   └── BitbucketRepositoryFetcher.swift  # Bitbucket API integration
├── CodeParsers/              # Language-specific parsers (8 files)
│   ├── SwiftCodeParser.swift
│   ├── SwiftSymbolExtractor.swift
│   ├── SwiftComplexityCalculator.swift
│   ├── SwiftLogicalUnitExtractor.swift
│   ├── TypeScriptCodeParser.swift
│   └── ... (additional parsers)
├── Embeddings/               # Vector embedding generators (1 file)
│   └── NaturalLanguageEmbeddings.swift  # Apple NL framework embeddings
├── VectorSearch/             # Vector similarity search (5 files)
│   ├── SupabaseVectorSearch.swift
│   └── ... (vector search implementations)
├── FullTextSearch/           # BM25/keyword search (5 files)
│   ├── BM25Scorer.swift
│   ├── KeywordTokenizer.swift
│   └── ... (full-text search implementations)
├── ContextualRetrieval/      # RAG retrieval pipeline (3 files)
│   ├── ChunkExpander.swift           # Expand chunks with context
│   ├── ExpandedChunk.swift           # Expanded chunk entity
│   └── SurroundingChunks.swift       # Surrounding context
├── Tokenization/             # Token counting implementations (3 files)
│   ├── ClaudeTokenizer.swift
│   ├── OpenAITokenizer.swift
│   └── AppleTokenizer.swift
├── Chunking/                 # Text/code chunking implementations (6 files)
│   ├── SemanticChunker.swift
│   ├── HierarchicalChunker.swift
│   ├── CodeStructureChunker.swift
│   ├── JinaLateChunker.swift
│   └── ... (chunking strategies)
├── Compression/              # Context compression implementations (2 files)
│   ├── AnthropicContextualEnricher.swift
│   └── MetaTokenCompressor.swift
├── Prompts/                  # Prompt template implementations (6 files)
│   ├── PromptLoader.swift
│   ├── PromptTemplate.swift
│   └── ... (prompt rendering)
├── Hashing/                  # Content hashing (1 file)
│   └── SHA256Hasher.swift
├── HTTP/                     # HTTP client utilities (5 files)
│   ├── HTTPClient.swift
│   ├── HTTPRequest.swift
│   ├── HTTPResponse.swift
│   ├── HTTPMethod.swift
│   └── HTTPError.swift
├── Interaction/              # User interaction implementations (1 file)
│   └── ConsoleInteractionHandler.swift
├── Monitoring/               # Debug/logging implementations (6 files)
│   ├── ConsoleLogger.swift
│   ├── FileLogger.swift
│   └── ... (monitoring utilities)
├── Environment/              # Environment configuration (2 files)
│   ├── EnvironmentReader.swift
│   └── EnvironmentVariables.swift
└── Utilities/                # Shared utilities (1 file)
    └── ArrayExtensions.swift
```

## Design Principles

### 1. Implement Domain Ports
Every adapter implements a Domain-defined port:
```swift
// Domain defines the contract
public protocol AIProviderPort {
    func generateText(prompt: String) async throws -> String
}

// Infrastructure implements it
public struct OpenAIProvider: AIProviderPort {
    private let apiKey: String
    private let httpClient: HTTPClient

    public func generateText(prompt: String) async throws -> String {
        // OpenAI-specific implementation
        let request = buildOpenAIRequest(prompt)
        let response = try await httpClient.execute(request)
        return parseOpenAIResponse(response)
    }
}
```

### 2. No Business Logic
Infrastructure only handles technical concerns:
```swift
// ✅ GOOD: Pure technical implementation
public struct SupabasePRDRepository: PRDRepositoryPort {
    public func save(_ document: PRDDocument) async throws -> PRDDocument {
        let dto = mapToDTO(document)  // ✅ Mapping
        let request = buildInsertRequest(dto)  // ✅ HTTP building
        let response = try await execute(request)  // ✅ Network call
        return mapToDomain(response)  // ✅ Mapping back
    }
}

// ❌ BAD: Business logic in infrastructure
public struct SupabasePRDRepository: PRDRepositoryPort {
    public func save(_ document: PRDDocument) async throws -> PRDDocument {
        // ❌ Validation is domain concern
        guard document.sections.count >= 3 else {
            throw Error.incomplete
        }

        // ❌ Business rule in infrastructure
        if document.title.contains("urgent") {
            document.priority = .high
        }
    }
}
```

### 3. Error Translation
Map external errors to domain errors:
```swift
public struct OpenAIProvider: AIProviderPort {
    public func generateText(prompt: String) async throws -> String {
        do {
            let response = try await openAI.complete(prompt)
            return response.text
        } catch let error as OpenAIError {
            // ✅ Translate to domain error
            throw mapToDomainError(error)
        }
    }

    private func mapToDomainError(_ error: OpenAIError) -> AIProviderError {
        switch error {
        case .rateLimitExceeded:
            return .rateLimited
        case .invalidAPIKey:
            return .authenticationFailed
        case .modelNotFound:
            return .modelNotAvailable
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
```

### 4. DTO Mapping
Keep external structures separate from domain:
```swift
// External DTO (matches Supabase schema)
struct PRDDocumentDTO: Codable {
    let id: String
    let title: String
    let content: String
    let created_at: String  // snake_case from DB
    let metadata_json: String
}

// Mapper
extension PRDDocumentDTO {
    func toDomain() throws -> PRDDocument {
        PRDDocument(
            id: UUID(uuidString: id)!,
            title: title,
            sections: try JSONDecoder().decode([PRDSection].self, from: content.data(using: .utf8)!),
            metadata: try JSONDecoder().decode(DocumentMetadata.self, from: metadata_json.data(using: .utf8)!),
            createdAt: ISO8601DateFormatter().date(from: created_at)!
        )
    }

    static func fromDomain(_ domain: PRDDocument) throws -> PRDDocumentDTO {
        PRDDocumentDTO(
            id: domain.id.uuidString,
            title: domain.title,
            content: String(data: try JSONEncoder().encode(domain.sections), encoding: .utf8)!,
            created_at: ISO8601DateFormatter().string(from: domain.createdAt),
            metadata_json: String(data: try JSONEncoder().encode(domain.metadata), encoding: .utf8)!
        )
    }
}
```

## Key Patterns

### Adapter Pattern
Each external service gets an adapter:
```swift
// Domain port
public protocol PRDRepositoryPort {
    func save(_ document: PRDDocument) async throws -> PRDDocument
    func findById(_ id: UUID) async throws -> PRDDocument?
}

// Supabase adapter
public struct SupabasePRDRepository: PRDRepositoryPort {
    private let client: SupabaseClient

    public func save(_ document: PRDDocument) async throws -> PRDDocument {
        // Supabase-specific implementation
    }

    public func findById(_ id: UUID) async throws -> PRDDocument? {
        // Supabase-specific implementation
    }
}

// In-memory adapter (for testing)
public struct InMemoryPRDRepository: PRDRepositoryPort {
    private var storage: [UUID: PRDDocument] = [:]

    public func save(_ document: PRDDocument) async throws -> PRDDocument {
        storage[document.id] = document
        return document
    }

    public func findById(_ id: UUID) async throws -> PRDDocument? {
        storage[id]
    }
}
```

### Strategy Pattern (Provider Selection)
Multiple implementations of same port:
```swift
// Multiple AI providers implement same port
let anthropicProvider: AIProviderPort = AnthropicProvider(apiKey: "...")
let openAIProvider: AIProviderPort = OpenAIProvider(apiKey: "...")
let googleProvider: AIProviderPort = GoogleProvider(apiKey: "...")

// Router selects based on strategy
public struct AIProviderRouter {
    func selectProvider(for task: TaskType) -> AIProviderPort {
        switch task {
        case .reasoning:
            return anthropicProvider  // Claude for reasoning
        case .codeGeneration:
            return openAIProvider     // GPT-4 for code
        case .analysis:
            return googleProvider     // Gemini for analysis
        }
    }
}
```

### Repository Pattern
Consistent data access:
```swift
public protocol RepositoryPort {
    associatedtype Entity: Identifiable

    func save(_ entity: Entity) async throws -> Entity
    func findById(_ id: UUID) async throws -> Entity?
    func findAll(limit: Int, offset: Int) async throws -> [Entity]
    func delete(_ id: UUID) async throws
}

public struct SupabaseRepository<T: Codable & Identifiable>: RepositoryPort {
    typealias Entity = T

    private let tableName: String
    private let client: SupabaseClient

    // Generic implementation for any Codable entity
}
```

## Integration Points

### Consumes From Domain
- **Ports**: Interfaces to implement
- **Entities**: Types for DTOs and mapping
- **Errors**: Domain errors to throw

### Consumes From Application
- **Use Case Contracts**: What workflows need
- **DTOs**: Request/response structures

### Provides To Composition
- **Concrete Implementations**: Actual adapters to wire
- **Factories**: Builder patterns for complex setup
- **Configuration**: Settings for external services

## Implementation Examples

### AI Provider Adapter
```swift
public struct AnthropicProvider: AIProviderPort {
    private let apiKey: String
    private let httpClient: HTTPClient
    private let baseURL = "https://api.anthropic.com"

    public init(apiKey: String, httpClient: HTTPClient = .shared) {
        self.apiKey = apiKey
        self.httpClient = httpClient
    }

    public func generateText(
        prompt: String,
        maxTokens: Int,
        temperature: Double
    ) async throws -> String {
        let request = buildRequest(
            prompt: prompt,
            maxTokens: maxTokens,
            temperature: temperature
        )

        let response = try await httpClient.execute(request)
        return try parseResponse(response)
    }

    public func streamText(
        prompt: String,
        maxTokens: Int,
        temperature: Double
    ) async throws -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
                do {
                    let stream = try await httpClient.stream(
                        buildStreamRequest(prompt: prompt, maxTokens: maxTokens, temperature: temperature)
                    )

                    for try await chunk in stream {
                        let text = try parseChunk(chunk)
                        continuation.yield(text)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }

    public var providerName: String { "Anthropic Claude" }
    public var modelName: String { "claude-3-5-sonnet-20241022" }

    // Private helpers < 40 lines each
    private func buildRequest(...) -> HTTPRequest { ... }
    private func parseResponse(_ data: Data) throws -> String { ... }
    private func buildStreamRequest(...) -> HTTPRequest { ... }
    private func parseChunk(_ data: Data) throws -> String { ... }
}
```

### Repository Adapter
```swift
public struct SupabaseCodebaseRepository: CodebaseRepositoryPort {
    private let client: SupabaseClient
    private let tableName = "codebase_projects"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func save(_ codebase: CodebaseProject) async throws -> CodebaseProject {
        let dto = CodebaseProjectDTO.fromDomain(codebase)

        let request = client.buildInsertRequest(
            table: tableName,
            data: dto
        )

        let response: [CodebaseProjectDTO] = try await client.execute(request)

        guard let savedDTO = response.first else {
            throw RepositoryError.saveFailed
        }

        return try savedDTO.toDomain()
    }

    public func searchFiles(
        in codebaseId: UUID,
        embedding: [Float],
        limit: Int,
        similarityThreshold: Double
    ) async throws -> [(file: CodeFile, similarity: Double)] {
        let request = client.buildVectorSearchRequest(
            table: "code_files",
            embeddingColumn: "embedding",
            queryEmbedding: embedding,
            limit: limit,
            threshold: similarityThreshold,
            filter: ["codebase_id": codebaseId.uuidString]
        )

        let results: [CodeFileSearchResult] = try await client.execute(request)

        return try results.map { result in
            (
                file: try result.file.toDomain(),
                similarity: result.similarity
            )
        }
    }
}
```

### Code Parser Adapter
```swift
public struct SwiftParser: CodeParserPort {
    public var supportedLanguage: ProgrammingLanguage { .swift }

    public func parse(_ code: String) async throws -> ParsedCode {
        let symbols = try extractSymbols(from: code)
        let imports = extractImports(from: code)
        let dependencies = analyzeDependencies(symbols, imports)

        return ParsedCode(
            language: .swift,
            symbols: symbols,
            imports: imports,
            dependencies: dependencies,
            metrics: calculateMetrics(code)
        )
    }

    public func extractSymbols(_ code: String) async throws -> [CodeSymbol] {
        var symbols: [CodeSymbol] = []

        // Extract classes
        symbols.append(contentsOf: extractClasses(from: code))

        // Extract structs
        symbols.append(contentsOf: extractStructs(from: code))

        // Extract enums
        symbols.append(contentsOf: extractEnums(from: code))

        // Extract protocols
        symbols.append(contentsOf: extractProtocols(from: code))

        return symbols
    }

    // Private extraction methods < 40 lines each
    private func extractClasses(from code: String) -> [CodeSymbol] { ... }
    private func extractStructs(from code: String) -> [CodeSymbol] { ... }
    private func extractEnums(from code: String) -> [CodeSymbol] { ... }
    private func extractProtocols(from code: String) -> [CodeSymbol] { ... }
    private func extractImports(from code: String) -> [String] { ... }
    private func analyzeDependencies(...) -> [Dependency] { ... }
    private func calculateMetrics(_ code: String) -> CodeMetrics { ... }
}
```

## Design Constraints

### Must
- ✅ Implement Domain ports exactly
- ✅ Handle all external I/O (network, DB, files)
- ✅ Map external data to/from Domain entities
- ✅ Translate external errors to Domain errors
- ✅ Be swappable (multiple implementations of same port)

### Must Not
- ❌ Contain business logic or validation rules
- ❌ Modify domain entities (only map)
- ❌ Depend on other Infrastructure implementations
- ❌ Expose external types to Domain/Application

## Testing Strategy

Infrastructure tests are **integration/contract tests**:
```swift
// Contract test: Verify port implementation
class SupabasePRDRepositoryTests: XCTestCase {
    var sut: SupabasePRDRepository!
    var testClient: SupabaseClient!

    override func setUp() async throws {
        testClient = SupabaseClient(/* test config */)
        sut = SupabasePRDRepository(client: testClient)
    }

    func testSaveAndRetrieve() async throws {
        // Given
        let document = PRDDocument(/* test data */)

        // When
        let saved = try await sut.save(document)
        let retrieved = try await sut.findById(saved.id)

        // Then
        XCTAssertEqual(retrieved?.id, document.id)
        XCTAssertEqual(retrieved?.title, document.title)
    }

    func testVectorSearch() async throws {
        // Test actual vector similarity search
    }
}
```

## Common Violations to Avoid

### ❌ Business Logic in Infrastructure
```swift
// BAD
public struct SupabasePRDRepository: PRDRepositoryPort {
    func save(_ doc: PRDDocument) async throws -> PRDDocument {
        if doc.sections.count < 3 {  // ❌ Business rule
            throw Error.incomplete
        }
        // ... save logic
    }
}
```

### ❌ Exposing External Types
```swift
// BAD
public struct OpenAIProvider: AIProviderPort {
    func generate(...) async throws -> OpenAIResponse {  // ❌ External type
        // ...
    }
}

// GOOD
public struct OpenAIProvider: AIProviderPort {
    func generateText(...) async throws -> String {  // ✅ Domain type
        let response: OpenAIResponse = try await api.complete(...)
        return response.choices.first?.text ?? ""
    }
}
```

### ❌ Tight Coupling
```swift
// BAD
public struct OpenAIProvider: AIProviderPort {
    private let supabase = SupabaseClient()  // ❌ Coupled to another adapter

    func generateText(...) async throws -> String {
        let cacheKey = try await supabase.getCacheKey(...)  // ❌ Wrong
    }
}
```

## Adding New Adapters

Checklist for new infrastructure adapters:

1. **Identify** the Domain port to implement
2. **Choose** external service/library
3. **Create** DTO types for external data
4. **Implement** port interface
5. **Map** between DTOs and Domain entities
6. **Translate** external errors to Domain errors
7. **Extract** methods to stay ≤ 40 lines
8. **Test** with actual or stubbed external service

## Related Documentation
- See `NAMING_CONVENTIONS.md` for comprehensive naming standards
- See `Domain/README.md` for ports to implement
- See `Application/README.md` for use case requirements
- See `Composition/README.md` for dependency wiring
- See `docs/architecture/overview.md` for full architecture
- See `ZERO_TOLERANCE_RULES.md` for coding standards
- See `docs/architecture/decisions/` for architectural decisions
