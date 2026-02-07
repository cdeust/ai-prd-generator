import AIPRDSharedUtilities
import Foundation

/// Swift Logical Unit Extractor
/// Extracts logical units (classes, structs, functions) from Swift code
/// Single Responsibility: Only logical unit extraction logic
final class SwiftLogicalUnitExtractor: Sendable {

    func extractLogicalUnits(
        from code: String
    ) -> [LogicalUnit] {
        var units: [LogicalUnit] = []
        let lines = code.components(separatedBy: .newlines)

        var currentUnit: (name: String, startLine: Int, lines: [String])? = nil
        var braceDepth = 0

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if currentUnit == nil {
                if let unitName = detectUnitStart(from: trimmed) {
                    currentUnit = (name: unitName, startLine: index + 1, lines: [line])
                    braceDepth = countBraces(in: line).open - countBraces(in: line).close
                    continue
                }
            }

            if var unit = currentUnit {
                unit.lines.append(line)
                let braces = countBraces(in: line)
                braceDepth += braces.open - braces.close

                if braceDepth == 0 {
                    let content = unit.lines.joined(separator: "\n")
                    units.append(LogicalUnit(
                        name: unit.name,
                        content: content,
                        startLine: unit.startLine,
                        endLine: index + 1
                    ))
                    currentUnit = nil
                } else {
                    currentUnit = unit
                }
            }
        }

        return units
    }

    private func detectUnitStart(from line: String) -> String? {
        if line.contains("class ") {
            return extractName(from: line, keyword: "class")
        }
        if line.contains("struct ") {
            return extractName(from: line, keyword: "struct")
        }
        if line.contains("protocol ") {
            return extractName(from: line, keyword: "protocol")
        }
        if line.contains("enum ") {
            return extractName(from: line, keyword: "enum")
        }
        if line.contains("func ") {
            return extractName(from: line, keyword: "func")
        }

        return nil
    }

    private func extractName(from line: String, keyword: String) -> String {
        let components = line.components(separatedBy: keyword)
        guard components.count > 1 else { return keyword }

        let afterKeyword = components[1].trimmingCharacters(in: .whitespaces)
        let name = afterKeyword.components(separatedBy: CharacterSet(charactersIn: ":{(<")).first ?? keyword

        return name.trimmingCharacters(in: .whitespaces)
    }

    private func countBraces(in line: String) -> (open: Int, close: Int) {
        let open = line.filter { $0 == "{" }.count
        let close = line.filter { $0 == "}" }.count
        return (open, close)
    }
}
