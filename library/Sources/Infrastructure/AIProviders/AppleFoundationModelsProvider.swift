import Foundation
import AIPRDSharedUtilities

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Apple Foundation Models AI Provider Implementation
/// Implements AIProviderPort using Apple's Foundation Models framework
/// Following Single Responsibility: Only handles Foundation Models API communication
/// Following naming convention: {Technology}Provider
///
/// Uses SystemLanguageModel for on-device and Private Cloud Compute
/// - Available since iOS 18.0, macOS 16.0
/// - On-device processing with optional Private Cloud Compute
/// - Privacy-preserving, can work offline
@available(iOS 26.0, macOS 26.0, *)
public final class AppleFoundationModelsProvider: AIProviderPort, Sendable {
    // MARK: - Properties

    private let processingMode: AppleFoundationModelsProcessingMode
    private let modelIdentifier: String
    private let contextWindowDetector: ContextWindowDetector

    // MARK: - Initialization

    public init(
        mode: AppleFoundationModelsProcessingMode = .hybrid,
        modelIdentifier: String = "foundation-model-default",
        initialContextEstimate: Int? = nil
    ) throws {
        self.processingMode = mode
        self.modelIdentifier = modelIdentifier

        // Initialize detector with conservative estimate or runtime detection
        self.contextWindowDetector = ContextWindowDetector(
            initialEstimate: initialContextEstimate ?? Self.detectContextWindowAtInit()
        )

        #if canImport(FoundationModels)
        // Check if model is available
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw AIProviderError.modelNotAvailable(
                "Foundation Models not available on this device"
            )
        }
        #else
        throw AIProviderError.modelNotAvailable(
            "Foundation Models framework not available"
        )
        #endif
    }

    // MARK: - AIProviderPort Implementation

    public func generateText(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> String {
        // Note: Apple Foundation Models does NOT support reasoning mode
        // Parameter is accepted for AIProviderPort conformance but ignored
        _ = reasoningEffort
        #if canImport(FoundationModels)
        try validatePromptLength(prompt)
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw AIProviderError.modelNotAvailable("Foundation Models not available")
        }
        let (systemInstructions, userPrompt) = extractInstructions(from: prompt)
        let estimatedTokens = estimateTokenCount(prompt)
        logPromptDebugInfo(prompt: prompt, systemInstructions: systemInstructions, userPrompt: userPrompt, estimatedTokens: estimatedTokens)
        return try await executeGeneration(
            systemInstructions: systemInstructions,
            userPrompt: userPrompt,
            estimatedTokens: estimatedTokens
        )
        #else
        throw AIProviderError.modelNotAvailable("Foundation Models not available on this platform")
        #endif
    }

    private func logPromptDebugInfo(
        prompt: String,
        systemInstructions: String,
        userPrompt: String,
        estimatedTokens: Int
    ) {
        print("\n🔍 DEBUG: Apple Foundation Models")
        print("📏 Context window: \(contextWindowDetector.getContextWindowSize()) tokens")
        print("📊 Estimated prompt: \(estimatedTokens) tokens")
        print("📋 System Instructions (\(systemInstructions.count) chars):")
        print(systemInstructions.prefix(200))
        print("\n📝 User Prompt (\(userPrompt.count) chars):")
        print(userPrompt.prefix(500))
        print("\n")
    }

    private func executeGeneration(
        systemInstructions: String,
        userPrompt: String,
        estimatedTokens: Int
    ) async throws -> String {
        #if canImport(FoundationModels)
        do {
            print("🔄 Creating session...")
            let session = LanguageModelSession(instructions: systemInstructions)
            print("📡 Calling session.respond()...")
            let output = try await session.respond(to: userPrompt)
            print("✅ Got response!")
            print("📤 Response (\(output.content.count) chars):")
            print(output.content.prefix(500))
            print("\n")
            contextWindowDetector.recordSuccess(tokenCount: estimatedTokens)
            return output.content
        } catch {
            let errorString = String(describing: error)
            if errorString.contains("exceeds the maximum allowed context") ||
               errorString.contains("context size") {
                let adjustedLimit = contextWindowDetector.recordFailure(
                    attemptedTokens: estimatedTokens,
                    error: error
                )
                print("💡 [AppleFoundationModels] Learned new limit: \(adjustedLimit) tokens")
                print("   This will be used for future requests to prevent overflow")
            }
            throw error
        }
        #else
        throw AIProviderError.modelNotAvailable("Foundation Models not available")
        #endif
    }

    public func streamText(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> AsyncStream<String> {
        // Note: Apple Foundation Models does NOT support reasoning mode
        // Parameter is accepted for AIProviderPort conformance but ignored
        _ = reasoningEffort
        #if canImport(FoundationModels)
        try validatePromptLength(prompt)
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw AIProviderError.modelNotAvailable("Foundation Models not available")
        }
        let (systemInstructions, userPrompt) = extractInstructions(from: prompt)
        let estimatedTokens = estimateTokenCount(prompt)
        let detector = contextWindowDetector

        return AsyncStream { continuation in
            Task {
                await self.executeStreamingGeneration(
                    systemInstructions: systemInstructions,
                    userPrompt: userPrompt,
                    estimatedTokens: estimatedTokens,
                    detector: detector,
                    continuation: continuation
                )
            }
        }
        #else
        throw AIProviderError.modelNotAvailable("Foundation Models not available on this platform")
        #endif
    }

    private func executeStreamingGeneration(
        systemInstructions: String,
        userPrompt: String,
        estimatedTokens: Int,
        detector: ContextWindowDetector,
        continuation: AsyncStream<String>.Continuation
    ) async {
        #if canImport(FoundationModels)
        do {
            print("🔄 Creating streaming session...")
            print("📏 Context window: \(detector.getContextWindowSize()) tokens")
            print("📊 Estimated prompt: \(estimatedTokens) tokens")
            let session = LanguageModelSession(instructions: systemInstructions)
            print("📡 Calling session.respond() for streaming...")
            let output = try await session.respond(to: userPrompt)
            print("✅ Got streaming response!")
            detector.recordSuccess(tokenCount: estimatedTokens)
            continuation.yield(output.content)
            continuation.finish()
        } catch {
            print("❌ Streaming error: \(error)")
            let errorString = String(describing: error)
            if errorString.contains("exceeds the maximum allowed context") ||
               errorString.contains("context size") {
                let adjustedLimit = detector.recordFailure(
                    attemptedTokens: estimatedTokens,
                    error: error
                )
                print("💡 [AppleFoundationModels] Learned new limit: \(adjustedLimit) tokens")
            }
            continuation.finish()
        }
        #endif
    }

    public var providerName: String { "Apple Foundation Models" }
    public var modelName: String { modelIdentifier }
    public var contextWindowSize: Int {
        contextWindowDetector.getContextWindowSize()
    }

    // MARK: - Private Methods

    /// Attempt to detect context window size at initialization
    /// Returns nil if detection not possible, caller will use conservative default
    private static func detectContextWindowAtInit() -> Int? {
        #if canImport(FoundationModels)
        // Try to query model capabilities if Apple exposes them
        // For now, return nil to use conservative default
        // Future: Check if SystemLanguageModel has context limit properties
        return nil
        #else
        return nil
        #endif
    }

    private func validatePromptLength(_ prompt: String) throws {
        let estimatedTokens = estimateTokenCount(prompt)
        let contextLimit = contextWindowDetector.getContextWindowSize()

        guard estimatedTokens <= contextLimit else {
            throw AIProviderError.promptTooLong(
                "Prompt exceeds maximum context (\(contextLimit) tokens)"
            )
        }
    }

    private func estimateTokenCount(_ text: String) -> Int {
        // Rough estimation: ~1.3 tokens per word for English
        let words = text.components(
            separatedBy: .whitespacesAndNewlines
        ).filter { !$0.isEmpty }
        return Int(Double(words.count) * 1.3)
    }

    private func extractInstructions(from prompt: String) -> (system: String, user: String) {
        // Extract <instruction> tag content as system instructions
        if let instructionRange = prompt.range(of: "<instruction>"),
           let instructionEndRange = prompt.range(of: "</instruction>") {
            let instructionStart = prompt.index(after: instructionRange.upperBound)
            let systemContent = prompt[instructionStart..<instructionEndRange.lowerBound]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Everything else becomes user content (input, task, requirements, etc.)
            let userContent = prompt.replacingOccurrences(of: "<instruction>\(systemContent)</instruction>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return (String(systemContent), userContent)
        }

        // Fallback: Look for "You are" pattern
        let lines = prompt.split(separator: "\n", omittingEmptySubsequences: false)

        if let firstLine = lines.first?.trimmingCharacters(in: .whitespaces),
           firstLine.lowercased().starts(with: "you are") {
            var systemLines: [String] = []
            var userLines: [String] = []
            var inSystem = true

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if inSystem {
                    if trimmed.isEmpty || trimmed == "---" {
                        inSystem = false
                        continue
                    }
                    systemLines.append(String(line))
                } else {
                    userLines.append(String(line))
                }
            }

            let system = systemLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            let user = userLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

            return (system, user.isEmpty ? prompt : user)
        }

        // No system instructions detected - use empty system
        return ("", prompt)
    }

}
