import Foundation
import Domain

/// Executes single TRM (Tiny Recursion Model) iteration
///
/// Performs one complete refinement cycle:
/// 1. Update latent state (z) using LLM
/// 2. Refine prediction (y) using updated state
///
/// Uses low temperature (0.2-0.3) for stability per TRM paper.
///
/// **Dependencies:**
/// - AIProviderPort: Text generation
/// - TRMPromptBuilder: Prompt construction
/// - TRMResponseParser: Response parsing
///
/// **Usage:**
/// ```swift
/// let engine = TRMIterationEngine(
///     aiProvider: provider,
///     promptBuilder: builder,
///     parser: parser
/// )
/// let newState = try await engine.updateLatentState(
///     problem: "What is 2+2?",
///     currentPrediction: "4",
///     previousState: state,
///     context: ""
/// )
/// ```
public struct TRMIterationEngine: Sendable {
    /// Low temperature for stable refinement (TRM paper)
    private let latentUpdateTemperature: Double = 0.2

    /// Slightly higher temperature for prediction refinement
    private let predictionTemperature: Double = 0.25

    /// Max tokens for latent state update
    private let latentUpdateMaxTokens: Int = 800

    /// Max tokens for prediction refinement
    private let predictionMaxTokens: Int = 1000

    private let aiProvider: AIProviderPort
    private let promptBuilder: TRMPromptBuilder
    private let parser: TRMResponseParser

    public init(
        aiProvider: AIProviderPort,
        promptBuilder: TRMPromptBuilder = TRMPromptBuilder(),
        parser: TRMResponseParser = TRMResponseParser()
    ) {
        self.aiProvider = aiProvider
        self.promptBuilder = promptBuilder
        self.parser = parser
    }

    // MARK: - Public Methods

    /// Update latent reasoning state (z)
    ///
    /// Generates new reasoning state by analyzing current prediction
    /// and identifying insights, errors, hypotheses, and uncertainties.
    ///
    /// - Parameters:
    ///   - problem: Original problem statement
    ///   - currentPrediction: Current answer (y)
    ///   - previousState: Previous reasoning state (z_old)
    ///   - context: Additional context
    /// - Returns: Updated refinement state (z_new)
    public func updateLatentState(
        problem: String,
        currentPrediction: String,
        previousState: RefinementState,
        context: String
    ) async throws -> RefinementState {
        // Build prompt for latent update
        let prompt = promptBuilder.buildLatentUpdatePrompt(
            problem: problem,
            prediction: currentPrediction,
            state: previousState,
            context: context
        )

        // Generate response with low temperature
        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: latentUpdateTemperature
        )

        // Parse response into structured state
        return parser.parseLatentState(response)
    }

    /// Refine prediction (y) using updated state
    ///
    /// Generates improved prediction by incorporating insights,
    /// correcting errors, and applying refined hypotheses.
    ///
    /// - Parameters:
    ///   - problem: Original problem statement
    ///   - latentState: Updated reasoning state (z_new)
    ///   - previousPrediction: Previous answer (y_old)
    ///   - context: Additional context
    /// - Returns: Refined prediction with metadata
    public func refinePrediction(
        problem: String,
        latentState: RefinementState,
        previousPrediction: String,
        context: String
    ) async throws -> (prediction: String, confidence: Double, reasoning: String) {
        // Build prompt for prediction refinement
        let prompt = promptBuilder.buildPredictionRefinementPrompt(
            problem: problem,
            state: latentState,
            previousPrediction: previousPrediction,
            context: context
        )

        // Generate response with slightly higher temperature
        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: predictionTemperature
        )

        // Parse response into prediction + confidence + reasoning
        return parser.parseRefinedPrediction(response)
    }
}
