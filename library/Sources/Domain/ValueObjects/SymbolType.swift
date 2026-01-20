import Foundation

/// Type of code symbol
/// Categorizes code declarations
public enum SymbolType: String, Sendable {
    case function
    case `class`
    case method
    case `struct`
    case `enum`
    case `protocol`
    case property
    case variable
}
