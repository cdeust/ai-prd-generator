import Foundation

/// Request/response logging for vision analysis debugging
public actor VisionLogger: Sendable {
    // MARK: - Log Entry

    public struct LogEntry: Sendable {
        public let timestamp: Date
        public let provider: String
        public let requestId: String
        public let request: RequestInfo
        public let response: ResponseInfo?
        public let error: ErrorInfo?
        public let duration: TimeInterval

        public struct RequestInfo: Sendable {
            public let imageSize: Int
            public let promptLength: Int
            public let timestamp: Date
        }

        public struct ResponseInfo: Sendable {
            public let componentCount: Int
            public let confidence: Double
            public let tokensUsed: Int?
            public let timestamp: Date
        }

        public struct ErrorInfo: Sendable {
            public let type: String
            public let message: String
            public let timestamp: Date
        }
    }

    // MARK: - Properties

    private var logs: [LogEntry] = []
    private let maxLogEntries: Int

    // MARK: - Initialization

    public init(maxLogEntries: Int = 1000) {
        self.maxLogEntries = maxLogEntries
    }

    // MARK: - Public Interface

    /// Log a request
    public func logRequest(
        provider: String,
        requestId: String,
        imageSize: Int,
        promptLength: Int
    ) {
        // Stored for later completion
    }

    /// Log successful response
    public func logSuccess(
        provider: String,
        requestId: String,
        imageSize: Int,
        promptLength: Int,
        componentCount: Int,
        confidence: Double,
        tokensUsed: Int?,
        duration: TimeInterval
    ) {
        let entry = LogEntry(
            timestamp: Date(),
            provider: provider,
            requestId: requestId,
            request: .init(
                imageSize: imageSize,
                promptLength: promptLength,
                timestamp: Date()
            ),
            response: .init(
                componentCount: componentCount,
                confidence: confidence,
                tokensUsed: tokensUsed,
                timestamp: Date()
            ),
            error: nil,
            duration: duration
        )

        addEntry(entry)
    }

    /// Log failed response
    public func logFailure(
        provider: String,
        requestId: String,
        imageSize: Int,
        promptLength: Int,
        error: Error,
        duration: TimeInterval
    ) {
        let entry = LogEntry(
            timestamp: Date(),
            provider: provider,
            requestId: requestId,
            request: .init(
                imageSize: imageSize,
                promptLength: promptLength,
                timestamp: Date()
            ),
            response: nil,
            error: .init(
                type: String(describing: type(of: error)),
                message: error.localizedDescription,
                timestamp: Date()
            ),
            duration: duration
        )

        addEntry(entry)
    }

    /// Get recent logs
    public func getRecentLogs(limit: Int = 100) -> [LogEntry] {
        Array(logs.suffix(limit))
    }

    /// Get logs for specific provider
    public func getLogs(
        for provider: String,
        limit: Int = 100
    ) -> [LogEntry] {
        logs.filter { $0.provider == provider }
            .suffix(limit)
            .map { $0 }
    }

    /// Clear all logs
    public func clear() {
        logs.removeAll()
    }

    // MARK: - Private Helpers

    private func addEntry(_ entry: LogEntry) {
        logs.append(entry)

        if logs.count > maxLogEntries {
            logs.removeFirst(logs.count - maxLogEntries)
        }
    }
}

