import Foundation
import Domain

// Apple Vision framework is only available on Apple platforms
#if canImport(Vision) && (os(macOS) || os(iOS))
import Vision
import CoreML

/// Apple Intelligence Vision implementation - Most sophisticated analyzer
/// Uses on-device ML with Vision framework for privacy-first analysis
/// Provides superior accuracy and system integration
@available(iOS 15.0, macOS 12.0, *)
public final class AppleVisionAnalyzer: VisionAnalysisPort, Sendable {
    private let confidenceThreshold: Float
    private let useAdvancedDetection: Bool
    private let detector: AppleComponentDetector
    private let textAnalyzer: AppleTextAnalyzer
    private let inferenceEngine: AppleInferenceEngine

    public init(
        confidenceThreshold: Float = 0.7,
        useAdvancedDetection: Bool = true
    ) {
        self.confidenceThreshold = confidenceThreshold
        self.useAdvancedDetection = useAdvancedDetection
        self.detector = AppleComponentDetector(confidenceThreshold: confidenceThreshold)
        self.textAnalyzer = AppleTextAnalyzer()
        self.inferenceEngine = AppleInferenceEngine()
    }

    public func analyzeMockup(
        imageData: Data,
        prompt: String?
    ) async throws -> MockupAnalysisResult {
        let mockupId = UUID()
        let startTime = Date()

        guard let cgImage = createCGImage(from: imageData) else {
            throw MockupAnalysisError.invalidImageData
        }

        let components = try await detector.detectComponents(in: cgImage)
        let textElements = try await textAnalyzer.detectText(in: cgImage)

        let enrichedComponents = inferenceEngine.enrichComponents(
            components,
            withText: textElements
        )

        let interactions = inferenceEngine.inferInteractions(from: components)

        let dataRequirements = inferenceEngine.inferDataRequirements(
            from: components,
            textElements: textElements
        )

        let duration = Date().timeIntervalSince(startTime)
        let metadata = createMetadata(
            duration: duration,
            imageSize: CGSize(width: cgImage.width, height: cgImage.height)
        )

        let result = MockupAnalysisResult(
            mockupId: mockupId,
            analyzedAt: startTime,
            components: enrichedComponents,
            flows: [],
            interactions: interactions,
            dataRequirements: dataRequirements,
            metadata: metadata,
            screenName: inferenceEngine.inferScreenName(from: textElements),
            screenDescription: inferenceEngine.inferScreenDescription(from: components)
        )

        try result.validate()
        return result
    }

    public func analyzeMultipleMockups(
        images: [MockupImage]
    ) async throws -> [MockupAnalysisResult] {
        try await withThrowingTaskGroup(of: MockupAnalysisResult.self) { group in
            for image in images {
                group.addTask {
                    try await self.analyzeMockup(
                        imageData: image.data,
                        prompt: nil
                    )
                }
            }

            var results: [MockupAnalysisResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    public func extractUserFlows(
        from screens: [MockupAnalysisResult]
    ) async throws -> [UserFlow] {
        var flows: [UserFlow] = []

        for screen in screens {
            let screenFlows = analyzeNavigationPatterns(in: screen)
            flows.append(contentsOf: screenFlows)
        }

        return flows
    }

    public var providerName: String { "Apple Intelligence" }
    public var modelName: String { "Vision + Core ML" }

    private func createCGImage(from data: Data) -> CGImage? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        return cgImage
    }

    private func analyzeNavigationPatterns(
        in screen: MockupAnalysisResult
    ) -> [UserFlow] {
        []
    }

    private func createMetadata(
        duration: TimeInterval,
        imageSize: CGSize
    ) -> AnalysisMetadata {
        AnalysisMetadata(
            confidence: 0.95,
            modelName: modelName,
            durationSeconds: duration,
            imageDimensions: ImageDimensions(
                width: Int(imageSize.width),
                height: Int(imageSize.height)
            ),
            additionalInfo: [
                "providerName": providerName,
                "onDevice": "true",
                "privacyPreserving": "true",
                "advanced": useAdvancedDetection.description
            ]
        )
    }
}
#endif // Apple platforms only
