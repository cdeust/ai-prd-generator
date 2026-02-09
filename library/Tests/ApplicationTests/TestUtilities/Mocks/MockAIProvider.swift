import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation

/// Configurable mock AI provider for testing
/// Follows professional testing standards from CLAUDE.md
public actor MockAIProvider: AIProviderPort {
    // MARK: - Configuration

    public enum ResponseMode: Sendable {
        case success(String)
        case failure(Error)
        case delayed(String, seconds: TimeInterval)
        case sequence([String])
    }

    public let providerName: String
    public let modelName: String
    public let contextWindowSize: Int

    private var responseMode: ResponseMode
    private var callCount: Int = 0
    private var lastPrompt: String?
    private var allPrompts: [String] = []
    private var lastTemperature: Double?
    private var lastReasoningEffort: ReasoningEffort?
    private var sequenceIndex: Int = 0

    // MARK: - Initialization

    public init(
        providerName: String = "MockProvider",
        modelName: String = "mock-model-1",
        contextWindowSize: Int = 128000,
        responseMode: ResponseMode = .success("Mock response")
    ) {
        self.providerName = providerName
        self.modelName = modelName
        self.contextWindowSize = contextWindowSize
        self.responseMode = responseMode
    }

    // MARK: - AIProviderPort

    public func generateText(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> String {
        callCount += 1
        lastPrompt = prompt
        allPrompts.append(prompt)
        lastTemperature = temperature
        lastReasoningEffort = reasoningEffort

        switch responseMode {
        case .success(let response):
            return response

        case .failure(let error):
            throw error

        case .delayed(let response, let seconds):
            try await Task.sleep(
                nanoseconds: UInt64(seconds * 1_000_000_000)
            )
            return response

        case .sequence(let responses):
            guard sequenceIndex < responses.count else {
                throw MockError.sequenceExhausted(
                    "No more responses (called \(callCount) times)"
                )
            }
            let response = responses[sequenceIndex]
            sequenceIndex += 1
            return response
        }
    }

    public func streamText(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> AsyncStream<String> {
        callCount += 1
        lastPrompt = prompt
        lastTemperature = temperature
        lastReasoningEffort = reasoningEffort

        return AsyncStream { continuation in
            Task {
                do {
                    let text = try await self.generateText(
                        prompt: prompt,
                        temperature: temperature,
                        reasoningEffort: reasoningEffort
                    )

                    // Simulate streaming by chunking
                    let chunkSize = 50
                    for i in stride(from: 0, to: text.count, by: chunkSize) {
                        let start = text.index(
                            text.startIndex,
                            offsetBy: i
                        )
                        let end = text.index(
                            start,
                            offsetBy: min(chunkSize, text.count - i)
                        )
                        continuation.yield(String(text[start..<end]))
                    }

                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }

    // MARK: - Test Inspection

    public func getCallCount() -> Int {
        callCount
    }

    public func getLastPrompt() -> String? {
        lastPrompt
    }

    public func getAllPrompts() -> [String] {
        allPrompts
    }

    public func getLastTemperature() -> Double? {
        lastTemperature
    }

    public func getLastReasoningEffort() -> ReasoningEffort? {
        lastReasoningEffort
    }

    public func reset() {
        callCount = 0
        lastPrompt = nil
        allPrompts = []
        lastTemperature = nil
        lastReasoningEffort = nil
        sequenceIndex = 0
    }

    public func configure(mode: ResponseMode) {
        responseMode = mode
        sequenceIndex = 0
    }
}

// MARK: - Mock Error

public enum MockError: Error, Sendable {
    case sequenceExhausted(String)
    case notConfigured
}
