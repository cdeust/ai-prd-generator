import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Swift Symbol Extractor
/// Extracts code symbols (classes, structs, functions, etc.) from Swift code
/// Single Responsibility: Only symbol extraction logic
final class SwiftSymbolExtractor: Sendable {

    func extractSymbols(from code: String) -> [CodeSymbol] {
        var symbols: [CodeSymbol] = []
        let lines = code.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let lineNumber = index + 1

            if let symbol = extractClassSymbol(from: trimmed, line: lineNumber) {
                symbols.append(symbol)
            }

            if let symbol = extractStructSymbol(from: trimmed, line: lineNumber) {
                symbols.append(symbol)
            }

            if let symbol = extractProtocolSymbol(from: trimmed, line: lineNumber) {
                symbols.append(symbol)
            }

            if let symbol = extractFunctionSymbol(from: trimmed, line: lineNumber) {
                symbols.append(symbol)
            }

            if let symbol = extractEnumSymbol(from: trimmed, line: lineNumber) {
                symbols.append(symbol)
            }
        }

        return symbols
    }

    private func extractClassSymbol(from line: String, line lineNumber: Int) -> CodeSymbol? {
        guard line.contains("class ") else { return nil }

        let name = extractName(from: line, keyword: "class")
        return CodeSymbol(
            name: name,
            symbolType: .class,
            startLine: lineNumber,
            endLine: lineNumber
        )
    }

    private func extractStructSymbol(from line: String, line lineNumber: Int) -> CodeSymbol? {
        guard line.contains("struct ") else { return nil }

        let name = extractName(from: line, keyword: "struct")
        return CodeSymbol(
            name: name,
            symbolType: .struct,
            startLine: lineNumber,
            endLine: lineNumber
        )
    }

    private func extractProtocolSymbol(from line: String, line lineNumber: Int) -> CodeSymbol? {
        guard line.contains("protocol ") else { return nil }

        let name = extractName(from: line, keyword: "protocol")
        return CodeSymbol(
            name: name,
            symbolType: .protocol,
            startLine: lineNumber,
            endLine: lineNumber
        )
    }

    private func extractFunctionSymbol(from line: String, line lineNumber: Int) -> CodeSymbol? {
        guard line.contains("func ") else { return nil }

        let name = extractName(from: line, keyword: "func")
        return CodeSymbol(
            name: name,
            symbolType: .function,
            startLine: lineNumber,
            endLine: lineNumber
        )
    }

    private func extractEnumSymbol(from line: String, line lineNumber: Int) -> CodeSymbol? {
        guard line.contains("enum ") else { return nil }

        let name = extractName(from: line, keyword: "enum")
        return CodeSymbol(
            name: name,
            symbolType: .enum,
            startLine: lineNumber,
            endLine: lineNumber
        )
    }

    private func extractName(from line: String, keyword: String) -> String {
        let components = line.components(separatedBy: keyword)
        guard components.count > 1 else { return keyword }

        let afterKeyword = components[1].trimmingCharacters(in: .whitespaces)
        let name = afterKeyword.components(separatedBy: CharacterSet(charactersIn: ":{(<")).first ?? keyword

        return name.trimmingCharacters(in: .whitespaces)
    }
}
