import Foundation

/// Type of code chunk
/// Categorizes semantic code segments
public enum ChunkType: String, Sendable {
    case function
    case `class`
    case method
    case `struct`
    case `enum`
    case `protocol`
    case `interface`
    case module
    case property
    case comment
    case `import`
    case declaration
    case other
}
