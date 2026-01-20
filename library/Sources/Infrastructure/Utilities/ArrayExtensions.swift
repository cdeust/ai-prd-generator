import Foundation

/// Array utility extensions for infrastructure layer
extension Array {
    /// Chunk array into smaller arrays of specified size
    /// - Parameter size: Maximum size of each chunk
    /// - Returns: Array of array chunks
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
