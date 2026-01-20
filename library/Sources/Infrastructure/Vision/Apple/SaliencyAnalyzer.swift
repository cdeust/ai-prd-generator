// Vision components require Apple platforms
#if os(macOS) || os(iOS)
import Foundation

// Apple Vision framework is only available on Apple platforms
#if canImport(Vision) && (os(macOS) || os(iOS))
import Vision

/// Analyzes visual saliency for UI hierarchy understanding
@available(iOS 15.0, macOS 12.0, *)
struct SaliencyAnalyzer: Sendable {
    func analyzeSaliency(
        in image: CGImage
    ) async throws -> [VNSaliencyImageObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNSaliencyImageObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                continuation.resume(returning: observations)
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func calculateSaliencyScore(
        for boundingBox: CGRect,
        in observations: [VNSaliencyImageObservation]
    ) -> Float {
        guard let observation = observations.first else {
            return 0.0
        }

        guard let salientObjects = observation.salientObjects else {
            return 0.0
        }

        let overlappingObjects = salientObjects.filter { object in
            object.boundingBox.intersects(boundingBox)
        }

        if overlappingObjects.isEmpty {
            return 0.0
        }

        let maxConfidence = overlappingObjects.map(\.confidence).max() ?? 0.0
        return maxConfidence
    }
}
#endif // Apple platforms only

#endif // os(macOS) || os(iOS)
