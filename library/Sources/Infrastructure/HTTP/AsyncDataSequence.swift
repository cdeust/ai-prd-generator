import AIPRDSharedUtilities
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Cross-platform URLSession async/await extensions
/// Provides async APIs for Linux where they don't exist natively
extension URLSession {
    #if !os(macOS) && !os(iOS) && !os(watchOS) && !os(tvOS)
    // Linux fallback using callback-based APIs

    /// Async wrapper for data(with:completionHandler:) on Linux
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data = data, let response = response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }

    /// Async wrapper for dataTask(with:completionHandler:) returning bytes stream on Linux
    public func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        // For Linux, we'll fetch all data and wrap it as AsyncBytes
        let (data, response) = try await self.data(for: request)
        let asyncBytes = AsyncDataSequence(data: data)
        return (asyncBytes, response)
    }

    // AsyncBytes type alias for Linux compatibility
    public typealias AsyncBytes = AsyncDataSequence
    #endif
}

#if !os(macOS) && !os(iOS) && !os(watchOS) && !os(tvOS)
/// Async sequence wrapper for Data on Linux
public struct AsyncDataSequence: AsyncSequence {
    public typealias Element = UInt8

    private let data: Data

    init(data: Data) {
        self.data = data
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(data: data)
    }

    /// Returns an async sequence of lines (for Server-Sent Events streaming)
    public var lines: AsyncLineSequence {
        AsyncLineSequence(bytes: self)
    }

    public struct Iterator: AsyncIteratorProtocol {
        private let data: Data
        private var index: Int = 0

        init(data: Data) {
            self.data = data
        }

        public mutating func next() async throws -> UInt8? {
            guard index < data.count else { return nil }
            let byte = data[index]
            index += 1
            return byte
        }
    }
}
#endif
