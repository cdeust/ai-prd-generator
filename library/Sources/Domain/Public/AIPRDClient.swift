import Foundation

/// Main client interface for AI PRD Library
/// This is what clients (iOS, macOS, backend) will use
/// Implementation details are hidden behind this clean interface
public protocol AIPRDClient: Sendable {

    // MARK: - Configuration

    /// Configure the library with necessary credentials
    /// - Parameters:
    ///   - supabaseURL: Supabase project URL
    ///   - supabaseKey: Supabase anonymous key
    func configure(supabaseURL: String, supabaseKey: String) async throws

    // MARK: - PRD Generation

    /// Generate a Product Requirements Document
    /// - Parameter request: PRD generation request
    /// - Returns: Generated PRD response
    func generatePRD(_ request: GeneratePRDRequest) async throws -> PRDResponse

    /// Generate PRD with streaming updates
    /// - Parameter request: PRD generation request
    /// - Returns: AsyncStream of PRD content chunks
    func generatePRDStream(_ request: GeneratePRDRequest) async throws -> AsyncStream<String>

    /// Get PRD by ID
    /// - Parameter id: PRD document ID
    /// - Returns: PRD response
    func getPRD(id: UUID) async throws -> PRDResponse

    /// List all PRDs
    /// - Parameters:
    ///   - limit: Maximum number of results
    ///   - offset: Offset for pagination
    /// - Returns: Array of PRD responses
    func listPRDs(limit: Int, offset: Int) async throws -> [PRDResponse]

    // MARK: - Codebase Management

    /// Index a codebase for RAG context
    /// - Parameter request: Indexing request
    /// - Returns: Indexing status
    func indexCodebase(_ request: IndexCodebaseRequest) async throws -> CodebaseIndexingStatus

    /// Get codebase indexing status
    /// - Parameter id: Codebase ID
    /// - Returns: Current indexing status
    func getCodebaseStatus(id: UUID) async throws -> CodebaseIndexingStatus

    /// Search codebase using semantic search
    /// - Parameter request: Search request
    /// - Returns: Relevant code chunks
    func searchCodebase(_ request: SearchCodebaseRequest) async throws -> [CodeSearchResult]

    /// Link codebase to PRD for context
    /// - Parameters:
    ///   - prdId: PRD ID
    ///   - codebaseId: Codebase ID
    func linkCodebaseToPRD(prdId: UUID, codebaseId: UUID) async throws

    // MARK: - Mockup Analysis

    /// Analyze mockups to extract requirements
    /// - Parameter mockups: Array of mockup inputs
    /// - Returns: Extracted requirements text
    func analyzeMockups(_ mockups: [MockupInput]) async throws -> String
}
