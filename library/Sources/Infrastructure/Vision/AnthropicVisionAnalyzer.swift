import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Domain

/// Anthropic Vision implementation with retry logic and robust parsing
/// Analyzes UI mockups using Anthropic's Vision API
@available(iOS 15.0, macOS 12.0, *)
public final class AnthropicVisionAnalyzer: VisionAnalysisPort, Sendable {
    internal let validator: ResponseValidator
    internal let jsonParser: AnthropicJSONParser
    internal let rateLimiter: RateLimiter
    private let apiClient: AnthropicAPIClient
    private let telemetry: VisionTelemetry?
    private let circuitBreaker: CircuitBreaker?
    private let logger: VisionLogger?
    internal let model: String
    internal let apiKey: String
    internal let baseURL: URL
    internal let apiVersion: String

    public init(
        apiKey: String,
        model: String = "claude-3-5-sonnet-20241022",
        baseURL: URL = URL(string: "https://api.anthropic.com/v1")!,
        apiVersion: String = "2023-06-01",
        retryPolicy: RetryPolicy = RetryPolicy(),
        requestsPerMinute: Int = 50,
        telemetry: VisionTelemetry? = nil,
        circuitBreaker: CircuitBreaker? = nil,
        logger: VisionLogger? = nil
    ) {
        self.model = model
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.apiVersion = apiVersion
        self.validator = ResponseValidator()
        self.jsonParser = AnthropicJSONParser()
        self.rateLimiter = RateLimiter(requestsPerMinute: requestsPerMinute)
        self.apiClient = AnthropicAPIClient(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            apiVersion: apiVersion,
            retryPolicy: retryPolicy
        )
        self.telemetry = telemetry
        self.circuitBreaker = circuitBreaker
        self.logger = logger
    }

    public func analyzeMockup(
        imageData: Data,
        prompt: String?
    ) async throws -> MockupAnalysisResult {
        let requestId = UUID()
        let mockupId = UUID()
        let startTime = Date()

        try await circuitBreaker?.shouldAllowRequest()

        do {
            let result = try await performAnalysis(
                imageData: imageData,
                prompt: prompt,
                mockupId: mockupId,
                requestId: requestId,
                startTime: startTime
            )

            await circuitBreaker?.recordSuccess()
            return result
        } catch {
            await circuitBreaker?.recordFailure()
            throw error
        }
    }

    private func performAnalysis(
        imageData: Data,
        prompt: String?,
        mockupId: UUID,
        requestId: UUID,
        startTime: Date
    ) async throws -> MockupAnalysisResult {
        let imageSize = imageData.count
        let visionPrompt = buildAnalysisPrompt(customPrompt: prompt)
        let promptLength = visionPrompt.count
        let requestIdString = requestId.uuidString

        await logger?.logRequest(
            provider: providerName,
            requestId: requestIdString,
            imageSize: imageSize,
            promptLength: promptLength
        )

        do {
            let executor = createExecutor()
            let analysisOutput = try await executor.execute {
                try await apiClient.callWithRetry(
                    imageData: imageData,
                    prompt: visionPrompt
                )
            }

            let duration = Date().timeIntervalSince(startTime)
            let processor = createProcessor()

            return try await processor.process(
                output: analysisOutput,
                mockupId: mockupId,
                analyzedAt: startTime,
                duration: duration,
                requestId: requestIdString,
                imageSize: imageSize,
                promptLength: promptLength
            )
        } catch {
            await recordFailure(
                error: error,
                duration: Date().timeIntervalSince(startTime),
                requestId: requestIdString,
                imageSize: imageSize,
                promptLength: promptLength
            )
            throw error
        }
    }

    private func createExecutor() -> AnthropicAnalysisExecutor {
        AnthropicAnalysisExecutor(
            rateLimiter: rateLimiter,
            jsonParser: jsonParser,
            validator: validator
        )
    }

    private func createProcessor() -> AnthropicResultProcessor {
        AnthropicResultProcessor(
            telemetry: telemetry,
            logger: logger,
            providerName: providerName,
            modelName: modelName
        )
    }

    private func recordFailure(
        error: Error,
        duration: TimeInterval,
        requestId: String,
        imageSize: Int,
        promptLength: Int
    ) async {
        await telemetry?.recordFailure(
            provider: providerName,
            error: error,
            duration: duration
        )

        await logger?.logFailure(
            provider: providerName,
            requestId: requestId,
            imageSize: imageSize,
            promptLength: promptLength,
            error: error,
            duration: duration
        )
    }

    public func analyzeMultipleMockups(
        images: [MockupImage]
    ) async throws -> [MockupAnalysisResult] {
        var results: [MockupAnalysisResult] = []

        for image in images {
            let result = try await analyzeMockup(
                imageData: image.data,
                prompt: nil
            )
            results.append(result)
        }

        return results
    }

    public func extractUserFlows(
        from screens: [MockupAnalysisResult]
    ) async throws -> [UserFlow] {
        guard !screens.isEmpty else {
            return []
        }

        var flows: [UserFlow] = []
        let screenMap = createScreenMap(from: screens)

        for screen in screens {
            let screenFlows = extractFlowsFromScreen(
                screen: screen,
                screenMap: screenMap
            )
            flows.append(contentsOf: screenFlows)
        }

        return flows
    }

    public var providerName: String { "Anthropic Vision" }
    public var modelName: String { model }

    internal func buildAnalysisPrompt(customPrompt: String?) -> String {
        let builder = VisionPromptBuilder()
        return builder.buildAnalysisPrompt(customPrompt: customPrompt)
    }

    internal func createVisionRequest(
        imageData: Data,
        prompt: String
    ) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("messages")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func createScreenMap(
        from screens: [MockupAnalysisResult]
    ) -> [String: MockupAnalysisResult] {
        var map: [String: MockupAnalysisResult] = [:]

        for screen in screens {
            if let name = screen.screenName {
                map[name] = screen
            }
        }

        return map
    }

    private func extractFlowsFromScreen(
        screen: MockupAnalysisResult,
        screenMap: [String: MockupAnalysisResult]
    ) -> [UserFlow] {
        var flows: [UserFlow] = []

        for interaction in screen.interactions {
            if let flow = createFlowFromInteraction(
                interaction: interaction,
                sourceScreen: screen,
                screenMap: screenMap
            ) {
                flows.append(flow)
            }
        }

        return flows
    }

    private func createFlowFromInteraction(
        interaction: Interaction,
        sourceScreen: MockupAnalysisResult,
        screenMap: [String: MockupAnalysisResult]
    ) -> UserFlow? {
        guard sourceScreen.screenName != nil else {
            return nil
        }

        return nil
    }

}
