import AIPRDSharedUtilities
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Dynamically detects and adapts to AI provider context window limits
/// Single Responsibility: Runtime context window size detection and adaptation
/// Following naming convention: {Purpose}Detector
@available(iOS 26.0, macOS 26.0, *)
public final class ContextWindowDetector: @unchecked Sendable {

    /// Detected context window size (learned from runtime behavior)
    /// Thread-safe access via lock (mutable state protected by NSLock)
    private let lock = NSLock()
    private var detectedSize: Int

    /// History of failures to learn from
    private var failureHistory: [(attemptedSize: Int, actualLimit: Int)] = []

    /// Initialize with optional initial estimate
    public init(initialEstimate: Int? = nil) {
        self.detectedSize = initialEstimate ?? 4096  // Conservative default
    }

    /// Get the current best estimate of context window size (synchronous, thread-safe)
    public func getContextWindowSize() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return detectedSize
    }

    /// Update context window size based on successful generation
    /// - Parameter tokenCount: Number of tokens successfully processed
    public func recordSuccess(tokenCount: Int) {
        lock.lock()
        defer { lock.unlock() }

        // Update our understanding if we successfully processed more than we thought possible
        if tokenCount > detectedSize {
            print("📈 [ContextWindowDetector] Detected larger window: \(detectedSize) → \(tokenCount)")
            detectedSize = tokenCount
        }
    }

    /// Learn from context window overflow error
    /// - Parameters:
    ///   - attemptedTokens: Number of tokens we tried to use
    ///   - error: The error received
    /// - Returns: Adjusted safe limit to retry with
    public func recordFailure(attemptedTokens: Int, error: Error) -> Int {
        lock.lock()
        defer { lock.unlock() }

        // Try to extract actual limit from error message
        let actualLimit = extractLimitFromError(error) ?? (attemptedTokens - 100)

        // Record this failure
        failureHistory.append((attemptedSize: attemptedTokens, actualLimit: actualLimit))

        // Update detected size to be conservative
        detectedSize = actualLimit

        print("🔴 [ContextWindowDetector] Context overflow detected:")
        print("   Attempted: \(attemptedTokens) tokens")
        print("   Actual limit: \(actualLimit) tokens")
        print("   New safe limit: \(actualLimit)")

        return actualLimit
    }

    /// Attempt to extract actual limit from error message
    /// Parses errors like: "Content contains 4091 tokens, which exceeds the maximum allowed context size of 4096"
    private func extractLimitFromError(_ error: Error) -> Int? {
        let errorString = String(describing: error)

        // Pattern: "maximum allowed context size of <number>"
        if let range = errorString.range(of: #"maximum allowed context size of (\d+)"#, options: .regularExpression) {
            let matchString = String(errorString[range])
            if let numberRange = matchString.range(of: #"\d+"#, options: .regularExpression) {
                let numberString = String(matchString[numberRange])
                return Int(numberString)
            }
        }

        // Pattern: "maximum allowed is <number>"
        if let range = errorString.range(of: #"maximum allowed is ([\d,\.]+)"#, options: .regularExpression) {
            let matchString = String(errorString[range])
            if let numberRange = matchString.range(of: #"[\d,\.]+"#, options: .regularExpression) {
                let numberString = String(matchString[numberRange])
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: ".", with: "")
                return Int(numberString)
            }
        }

        return nil
    }

    /// Get diagnostics about detected limits
    public func getDiagnostics() -> ContextWindowDiagnostics {
        lock.lock()
        defer { lock.unlock() }

        return ContextWindowDiagnostics(
            currentEstimate: detectedSize,
            failureCount: failureHistory.count,
            lastKnownLimit: failureHistory.last?.actualLimit
        )
    }
}
