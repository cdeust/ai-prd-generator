import Foundation

/// LLM configuration parameters loaded from environment variables
///
/// Environment Variables:
/// - `LLM_MAX_OUTPUT_TOKENS`: Maximum tokens for LLM responses (default: 8192)
/// - `LLM_TEMPERATURE_DETERMINISTIC`: Temperature for deterministic tasks (default: 0.0)
/// - `LLM_TEMPERATURE_CONSERVATIVE`: Temperature for conservative generation (default: 0.2)
/// - `LLM_TEMPERATURE_BALANCED`: Temperature for balanced tasks (default: 0.5)
/// - `LLM_TEMPERATURE_CREATIVE`: Temperature for creative generation (default: 0.7)
/// - `RAG_SIMILARITY_THRESHOLD`: Minimum similarity for RAG results (default: 0.5)
/// - `VERIFICATION_CONFIDENCE_THRESHOLD`: Confidence threshold for verification (default: 0.75)
/// - `LLM_TIMEOUT_SECONDS`: Request timeout in seconds (default: 120)
/// - `LLM_MAX_RETRIES`: Maximum retry attempts (default: 3)
public struct LLMConfiguration: Sendable {

    // MARK: - Token Limits

    /// Maximum output tokens for LLM responses
    /// Env: LLM_MAX_OUTPUT_TOKENS (default: 8192)
    public let maxOutputTokens: Int

    /// Context window reserved for output (percentage of total)
    /// Env: LLM_OUTPUT_RESERVE_PERCENTAGE (default: 0.25)
    public let outputReservePercentage: Double

    // MARK: - Temperature Presets

    /// Temperature for deterministic tasks (verification, parsing)
    /// Env: LLM_TEMPERATURE_DETERMINISTIC (default: 0.0)
    public let temperatureDeterministic: Double

    /// Temperature for conservative generation (analysis, extraction)
    /// Env: LLM_TEMPERATURE_CONSERVATIVE (default: 0.2)
    public let temperatureConservative: Double

    /// Temperature for balanced tasks (standard generation)
    /// Env: LLM_TEMPERATURE_BALANCED (default: 0.5)
    public let temperatureBalanced: Double

    /// Temperature for creative generation (brainstorming, ideation)
    /// Env: LLM_TEMPERATURE_CREATIVE (default: 0.7)
    public let temperatureCreative: Double

    // MARK: - Thresholds

    /// Minimum similarity score for RAG search results (0.0-1.0)
    /// Env: RAG_SIMILARITY_THRESHOLD (default: 0.5)
    public let ragSimilarityThreshold: Float

    /// Confidence threshold for verification passes (0.0-1.0)
    /// Env: VERIFICATION_CONFIDENCE_THRESHOLD (default: 0.75)
    public let verificationConfidenceThreshold: Double

    /// Injection detection high confidence threshold (triggers immediate block)
    /// Env: INJECTION_HIGH_CONFIDENCE_THRESHOLD (default: 0.7)
    public let injectionHighConfidenceThreshold: Double

    /// Injection detection medium confidence threshold (triggers secondary check)
    /// Env: INJECTION_MEDIUM_CONFIDENCE_THRESHOLD (default: 0.3)
    public let injectionMediumConfidenceThreshold: Double

    // MARK: - Reliability

    /// Request timeout in seconds
    /// Env: LLM_TIMEOUT_SECONDS (default: 120)
    public let timeoutSeconds: Int

    /// Maximum retry attempts for failed requests
    /// Env: LLM_MAX_RETRIES (default: 3)
    public let maxRetries: Int

    /// Circuit breaker failure threshold before opening
    /// Env: CIRCUIT_BREAKER_FAILURE_THRESHOLD (default: 5)
    public let circuitBreakerFailureThreshold: Int

    // MARK: - Token Budgets

    /// Token budget per PRD section
    /// Env: SECTION_TOKEN_BUDGET (default: 4000)
    public let sectionTokenBudget: Int

    /// Minimum tokens reserved for system prompt
    /// Env: SYSTEM_PROMPT_TOKEN_RESERVE (default: 500)
    public let systemPromptTokenReserve: Int

    // MARK: - Reasoning

    /// Token budget for low reasoning effort
    /// Env: REASONING_TOKENS_LOW (default: 10000)
    public let reasoningTokensLow: Int

    /// Token budget for medium reasoning effort
    /// Env: REASONING_TOKENS_MEDIUM (default: 25000)
    public let reasoningTokensMedium: Int

    /// Token budget for high reasoning effort
    /// Env: REASONING_TOKENS_HIGH (default: 50000)
    public let reasoningTokensHigh: Int

    // MARK: - Initialization

    public init(
        maxOutputTokens: Int = 8192,
        outputReservePercentage: Double = 0.25,
        temperatureDeterministic: Double = 0.0,
        temperatureConservative: Double = 0.2,
        temperatureBalanced: Double = 0.5,
        temperatureCreative: Double = 0.7,
        ragSimilarityThreshold: Float = 0.5,
        verificationConfidenceThreshold: Double = 0.75,
        injectionHighConfidenceThreshold: Double = 0.7,
        injectionMediumConfidenceThreshold: Double = 0.3,
        timeoutSeconds: Int = 120,
        maxRetries: Int = 3,
        circuitBreakerFailureThreshold: Int = 5,
        sectionTokenBudget: Int = 4000,
        systemPromptTokenReserve: Int = 500,
        reasoningTokensLow: Int = 10000,
        reasoningTokensMedium: Int = 25000,
        reasoningTokensHigh: Int = 50000
    ) {
        self.maxOutputTokens = maxOutputTokens
        self.outputReservePercentage = outputReservePercentage
        self.temperatureDeterministic = temperatureDeterministic
        self.temperatureConservative = temperatureConservative
        self.temperatureBalanced = temperatureBalanced
        self.temperatureCreative = temperatureCreative
        self.ragSimilarityThreshold = ragSimilarityThreshold
        self.verificationConfidenceThreshold = verificationConfidenceThreshold
        self.injectionHighConfidenceThreshold = injectionHighConfidenceThreshold
        self.injectionMediumConfidenceThreshold = injectionMediumConfidenceThreshold
        self.timeoutSeconds = timeoutSeconds
        self.maxRetries = maxRetries
        self.circuitBreakerFailureThreshold = circuitBreakerFailureThreshold
        self.sectionTokenBudget = sectionTokenBudget
        self.systemPromptTokenReserve = systemPromptTokenReserve
        self.reasoningTokensLow = reasoningTokensLow
        self.reasoningTokensMedium = reasoningTokensMedium
        self.reasoningTokensHigh = reasoningTokensHigh
    }

    /// Default configuration with sensible defaults
    public static let `default` = LLMConfiguration()

    /// Load configuration from environment variables
    public static func fromEnvironment() -> LLMConfiguration {
        let env = ProcessInfo.processInfo.environment

        return LLMConfiguration(
            maxOutputTokens: Int(env["LLM_MAX_OUTPUT_TOKENS"] ?? "") ?? 8192,
            outputReservePercentage: Double(env["LLM_OUTPUT_RESERVE_PERCENTAGE"] ?? "") ?? 0.25,
            temperatureDeterministic: Double(env["LLM_TEMPERATURE_DETERMINISTIC"] ?? "") ?? 0.0,
            temperatureConservative: Double(env["LLM_TEMPERATURE_CONSERVATIVE"] ?? "") ?? 0.2,
            temperatureBalanced: Double(env["LLM_TEMPERATURE_BALANCED"] ?? "") ?? 0.5,
            temperatureCreative: Double(env["LLM_TEMPERATURE_CREATIVE"] ?? "") ?? 0.7,
            ragSimilarityThreshold: Float(env["RAG_SIMILARITY_THRESHOLD"] ?? "") ?? 0.5,
            verificationConfidenceThreshold: Double(env["VERIFICATION_CONFIDENCE_THRESHOLD"] ?? "") ?? 0.75,
            injectionHighConfidenceThreshold: Double(env["INJECTION_HIGH_CONFIDENCE_THRESHOLD"] ?? "") ?? 0.7,
            injectionMediumConfidenceThreshold: Double(env["INJECTION_MEDIUM_CONFIDENCE_THRESHOLD"] ?? "") ?? 0.3,
            timeoutSeconds: Int(env["LLM_TIMEOUT_SECONDS"] ?? "") ?? 120,
            maxRetries: Int(env["LLM_MAX_RETRIES"] ?? "") ?? 3,
            circuitBreakerFailureThreshold: Int(env["CIRCUIT_BREAKER_FAILURE_THRESHOLD"] ?? "") ?? 5,
            sectionTokenBudget: Int(env["SECTION_TOKEN_BUDGET"] ?? "") ?? 4000,
            systemPromptTokenReserve: Int(env["SYSTEM_PROMPT_TOKEN_RESERVE"] ?? "") ?? 500,
            reasoningTokensLow: Int(env["REASONING_TOKENS_LOW"] ?? "") ?? 10000,
            reasoningTokensMedium: Int(env["REASONING_TOKENS_MEDIUM"] ?? "") ?? 25000,
            reasoningTokensHigh: Int(env["REASONING_TOKENS_HIGH"] ?? "") ?? 50000
        )
    }
}

// MARK: - Temperature Selection Helpers

extension LLMConfiguration {

    /// Temperature for the given task type
    public func temperature(for taskType: LLMTaskType) -> Double {
        switch taskType {
        case .verification, .parsing, .extraction:
            return temperatureDeterministic
        case .analysis, .summarization:
            return temperatureConservative
        case .generation, .reasoning:
            return temperatureBalanced
        case .brainstorming, .ideation:
            return temperatureCreative
        }
    }

    /// Reasoning tokens for the given effort level
    public func reasoningTokens(for effort: ReasoningEffortLevel) -> Int {
        switch effort {
        case .low:
            return reasoningTokensLow
        case .medium:
            return reasoningTokensMedium
        case .high:
            return reasoningTokensHigh
        }
    }
}

