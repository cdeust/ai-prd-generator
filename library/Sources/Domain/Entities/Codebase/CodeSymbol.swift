import Foundation

/// Code symbol (function, class, struct, etc.)
/// Domain entity representing a code declaration
public struct CodeSymbol: Sendable {
    public let name: String
    public let symbolType: SymbolType
    public let startLine: Int
    public let endLine: Int
    public let signature: String?
    public let documentation: String?

    public init(
        name: String,
        symbolType: SymbolType,
        startLine: Int,
        endLine: Int,
        signature: String? = nil,
        documentation: String? = nil
    ) {
        self.name = name
        self.symbolType = symbolType
        self.startLine = startLine
        self.endLine = endLine
        self.signature = signature
        self.documentation = documentation
    }
}
