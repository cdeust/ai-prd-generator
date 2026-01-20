import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Domain

/// Google Gemini Vision implementation with retry logic and cost tracking
/// Uses Gemini Pro Vision for mockup analysis
@available(iOS 15.0, macOS 12.0, *)
public final class GeminiVisionAnalyzer: VisionAnalysisPort, Sendable {
    private let validator: ResponseValidator
    private let jsonParser: GeminiJSONParser
    internal let rateLimiter: RateLimiter
    private let apiClient: GeminiAPIClient
    private let telemetry: VisionTelemetry?
    private let circuitBreaker: CircuitBreaker?
    private let logger: VisionLogger?
    internal let model: String
    internal let apiKey: String
    internal let baseURL: URL
    internal let errorMapper: GeminiErrorMapper

    public init(
        apiKey: String,
        model: String = "gemini-pro-vision",
        baseURL: URL = URL(string: "https://generativelanguage.googleapis.com/v1")!,
        retryPolicy: RetryPolicy = RetryPolicy(),
        requestsPerMinute: Int = 50,
        costTracker: CostTracker = CostTracker(),
        telemetry: VisionTelemetry? = nil,
        circuitBreaker: CircuitBreaker? = nil,
        logger: VisionLogger? = nil
    ) {
        self.model = model
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.errorMapper = GeminiErrorMapper()
        self.validator = ResponseValidator()
        self.jsonParser = GeminiJSONParser()
        self.rateLimiter = RateLimiter(requestsPerMinute: requestsPerMinute)
        self.apiClient = GeminiAPIClient(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            retryPolicy: retryPolicy,
            errorMapper: self.errorMapper,
            costTracker: costTracker
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
        let visionPrompt = buildPrompt(customPrompt: prompt)
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

    private func createExecutor() -> GeminiAnalysisExecutor {
        GeminiAnalysisExecutor(
            rateLimiter: rateLimiter,
            jsonParser: jsonParser,
            validator: validator
        )
    }

    private func createProcessor() -> GeminiResultProcessor {
        GeminiResultProcessor(
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
        []
    }

    public var providerName: String { "Google Gemini Vision" }
    public var modelName: String { model }

    internal func buildPrompt(customPrompt: String?) -> String {
        let builder = VisionPromptBuilder()
        return builder.buildAnalysisPrompt(customPrompt: customPrompt)
    }
}
