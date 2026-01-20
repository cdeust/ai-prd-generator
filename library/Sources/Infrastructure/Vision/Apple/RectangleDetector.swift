// Vision components require Apple platforms
#if os(macOS) || os(iOS)
import Foundation

// Apple Vision framework is only available on Apple platforms
#if canImport(Vision) && (os(macOS) || os(iOS))
import Vision

/// Detects UI component boundaries using rectangle detection
@available(iOS 15.0, macOS 12.0, *)
struct RectangleDetector: Sendable {
    private let minimumConfidence: Float
    private let minimumSize: Float
    private let maximumObservations: Int

    init(
        minimumConfidence: Float = 0.75,
        minimumSize: Float = 0.01,
        maximumObservations: Int = 100
    ) {
        self.minimumConfidence = minimumConfidence
        self.minimumSize = minimumSize
        self.maximumObservations = maximumObservations
    }

    func detectRectangles(
        in image: CGImage
    ) async throws -> [VNRectangleObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let filtered = observations.filter {
                    $0.confidence >= self.minimumConfidence
                }
                continuation.resume(returning: filtered)
            }

            configureRequest(request)

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func configureRequest(_ request: VNDetectRectanglesRequest) {
        request.minimumAspectRatio = 0.2
        request.maximumAspectRatio = 10.0
        request.minimumSize = minimumSize
        request.maximumObservations = maximumObservations
        request.quadratureTolerance = 15.0
    }
}
#endif // Apple platforms only

#endif // os(macOS) || os(iOS)
