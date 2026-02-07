import AIPRDSharedUtilities
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if !os(macOS) && !os(iOS) && !os(watchOS) && !os(tvOS)
/// Async sequence that splits bytes into lines
public struct AsyncLineSequence: AsyncSequence {
    public typealias Element = String

    private let bytes: AsyncDataSequence

    init(bytes: AsyncDataSequence) {
        self.bytes = bytes
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(bytes: bytes.makeAsyncIterator())
    }

    public struct Iterator: AsyncIteratorProtocol {
        private var bytesIterator: AsyncDataSequence.Iterator
        private var buffer: [UInt8] = []

        init(bytes: AsyncDataSequence.Iterator) {
            self.bytesIterator = bytes
        }

        public mutating func next() async throws -> String? {
            // Read bytes until we find a newline or reach the end
            while let byte = try await bytesIterator.next() {
                if byte == UInt8(ascii: "\n") {
                    // Found newline - return accumulated line
                    let line = String(decoding: buffer, as: UTF8.self)
                    buffer.removeAll(keepingCapacity: true)

                    // Trim trailing carriage return if present
                    if line.hasSuffix("\r") {
                        return String(line.dropLast())
                    }
                    return line
                } else {
                    buffer.append(byte)
                }
            }

            // End of stream - return remaining buffer if non-empty
            if !buffer.isEmpty {
                let line = String(decoding: buffer, as: UTF8.self)
                buffer.removeAll()
                return line
            }

            return nil
        }
    }
}
#endif
