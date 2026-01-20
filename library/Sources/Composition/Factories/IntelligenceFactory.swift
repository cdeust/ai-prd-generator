import Foundation
import Domain
import Application
import InfrastructureCore

/// Factory for creating intelligence tracking components
/// Handles creation of all intelligence-related repositories and services
struct IntelligenceFactory {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    /// Create the intelligence tracker service
    func createIntelligenceTracker() throws -> IntelligenceTrackerService {
        let databaseClient = try createSupabaseDatabaseClient()

        return IntelligenceTrackerService(
            llmTracker: SupabaseLLMInteractionRepository(databaseClient: databaseClient),
            strategyTracker: SupabaseStrategyDecisionRepository(databaseClient: databaseClient),
            ragTracker: SupabaseRAGContextRepository(databaseClient: databaseClient),
            mockupTracker: SupabaseMockupAnalysisRepository(databaseClient: databaseClient),
            clarificationTracker: SupabaseClarificationRepository(databaseClient: databaseClient),
            thinkingChainTracker: SupabaseThinkingChainRepository(databaseClient: databaseClient),
            metricsTracker: SupabasePerformanceMetricsRepository(databaseClient: databaseClient)
        )
    }

    /// Create individual repositories for direct access if needed
    func createLLMInteractionTracker() throws -> LLMInteractionTrackerPort {
        let databaseClient = try createSupabaseDatabaseClient()
        return SupabaseLLMInteractionRepository(databaseClient: databaseClient)
    }

    func createStrategyDecisionTracker() throws -> StrategyDecisionTrackerPort {
        let databaseClient = try createSupabaseDatabaseClient()
        return SupabaseStrategyDecisionRepository(databaseClient: databaseClient)
    }

    func createRAGContextTracker() throws -> RAGContextTrackerPort {
        let databaseClient = try createSupabaseDatabaseClient()
        return SupabaseRAGContextRepository(databaseClient: databaseClient)
    }

    func createPerformanceMetricsTracker() throws -> PerformanceMetricsTrackerPort {
        let databaseClient = try createSupabaseDatabaseClient()
        return SupabasePerformanceMetricsRepository(databaseClient: databaseClient)
    }

    private func createSupabaseDatabaseClient() throws -> SupabaseDatabasePort {
        guard let urlString = configuration.supabaseURL,
              let url = URL(string: urlString),
              let key = configuration.supabaseKey else {
            throw ConfigurationError.missingSupabaseCredentials
        }

        let supabaseClient = SupabaseClient(projectURL: url, apiKey: key)
        return SupabaseDatabaseClient(supabaseClient: supabaseClient)
    }
}
