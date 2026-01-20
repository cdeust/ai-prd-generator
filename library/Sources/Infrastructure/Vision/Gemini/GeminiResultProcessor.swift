import Foundation
import Domain

/// Processes Google Gemini Vision analysis results with telemetry and logging
/// Separates result processing from execution for testability
@available(iOS 15.0, macOS 12.0, *)
internal struct GeminiResultProcessor: Sendable {
    private let telemetry: VisionTelemetry?
    private let logger: VisionLogger?
    private let providerName: String
    private let modelName: String

    internal init(
        telemetry: VisionTelemetry?,
        logger: VisionLogger?,
        providerName: String,
        modelName: String
    ) {
        self.telemetry = telemetry
        self.logger = logger
        self.providerName = providerName
        self.modelName = modelName
    }

    internal func process(
        output: VisionAnalysisOutput,
        mockupId: UUID,
        analyzedAt: Date,
        duration: TimeInterval,
        requestId: String,
        imageSize: Int,
        promptLength: Int
    ) async throws -> MockupAnalysisResult {
        let mapper = AnalysisResultMapper()
        let result = try mapper.map(
            output: output,
            mockupId: mockupId,
            analyzedAt: analyzedAt,
            duration: duration,
            modelName: modelName,
            providerName: providerName
        )

        await recordSuccess(
            result: result,
            duration: duration,
            requestId: requestId,
            imageSize: imageSize,
            promptLength: promptLength
        )

        return result
    }

    private func recordSuccess(
        result: MockupAnalysisResult,
        duration: TimeInterval,
        requestId: String,
        imageSize: Int,
        promptLength: Int
    ) async {
        await telemetry?.recordSuccess(
            provider: providerName,
            duration: duration,
            componentCount: result.components.count,
            confidence: result.metadata.confidence
        )

        await logger?.logSuccess(
            provider: providerName,
            requestId: requestId,
            imageSize: imageSize,
            promptLength: promptLength,
            componentCount: result.components.count,
            confidence: result.metadata.confidence,
            tokensUsed: nil,
            duration: duration
        )
    }
}

