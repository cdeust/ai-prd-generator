// Vision components require Apple platforms
#if os(macOS) || os(iOS)
import Foundation
import Domain

// Apple Vision framework is only available on Apple platforms
#if canImport(Vision) && (os(macOS) || os(iOS))
import Vision

/// Detects UI components using comprehensive Apple Vision pipeline
@available(iOS 15.0, macOS 12.0, *)
struct AppleComponentDetector: Sendable {
    private let confidenceThreshold: Float
    private let rectangleDetector: RectangleDetector
    private let saliencyAnalyzer: SaliencyAnalyzer
    private let correlator: DetectionCorrelator
    private let imageClassifier: ImageClassifier?
    private let coreMLIntegration: CoreMLIntegration?

    init(
        confidenceThreshold: Float = 0.7,
        enableClassification: Bool = true,
        coreMLModelURL: URL? = nil
    ) {
        self.confidenceThreshold = confidenceThreshold
        self.rectangleDetector = RectangleDetector(
            minimumConfidence: confidenceThreshold
        )
        self.saliencyAnalyzer = SaliencyAnalyzer()
        self.correlator = DetectionCorrelator()
        self.imageClassifier = enableClassification
            ? ImageClassifier()
            : nil
        self.coreMLIntegration = coreMLModelURL != nil
            ? CoreMLIntegration(modelURL: coreMLModelURL)
            : nil
    }

    func detectComponents(
        in image: CGImage
    ) async throws -> [DetectedComponent] {
        async let rectangles = rectangleDetector.detectRectangles(in: image)
        async let text = detectText(in: image)
        async let saliency = saliencyAnalyzer.analyzeSaliency(in: image)

        let (detectedRects, textElements, salientRegions) = try await (
            rectangles,
            text,
            saliency
        )

        var components = correlator.correlateDetections(
            rectangles: detectedRects,
            text: textElements,
            saliency: salientRegions
        )

        components = try await enhanceWithClassification(
            components: components,
            image: image
        )

        return components.filter {
            $0.confidence >= confidenceThreshold
        }
    }

    private func enhanceWithClassification(
        components: [DetectedComponent],
        image: CGImage
    ) async throws -> [DetectedComponent] {
        return components
    }

    private func detectText(
        in image: CGImage
    ) async throws -> [VNRecognizedTextObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                continuation.resume(returning: observations)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
#endif // Apple platforms only

#endif // os(macOS) || os(iOS)
