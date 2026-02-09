import AIPRDSharedUtilities
import Foundation

/// Extracts imports from source code based on file extension
/// Supports multiple programming languages through pattern matching
struct ImportExtractor: Sendable {

    /// Extract imports from code based on file extension
    func extractImports(from code: String, fileExtension ext: String) -> [String] {
        var imports: [String] = []
        let lines = code.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let importName = extractImportFromLine(trimmed, fileExtension: ext) {
                imports.append(importName)
            }
        }

        return imports
    }

    private func extractImportFromLine(_ line: String, fileExtension ext: String) -> String? {
        switch ext {
        case "swift":
            return extractSwiftImport(line)
        case "m", "mm", "h":
            return extractObjectiveCImport(line)
        case "py":
            return extractPythonImport(line)
        case "js", "jsx", "ts", "tsx", "mjs", "cjs":
            return extractJSImport(line)
        case "java", "kt", "kts":
            return extractJavaImport(line)
        case "go":
            return extractGoImport(line)
        case "rs":
            return extractRustImport(line)
        case "cs":
            return extractCSharpImport(line)
        case "rb":
            return extractRubyImport(line)
        case "php":
            return extractPHPImport(line)
        case "c", "cpp", "cc", "cxx", "hpp":
            return extractCImport(line)
        case "scala":
            return extractScalaImport(line)
        case "dart":
            return extractDartImport(line)
        case "r":
            return extractRImport(line)
        case "lua":
            return extractLuaImport(line)
        default:
            return nil
        }
    }

    // MARK: - Swift

    private func extractSwiftImport(_ line: String) -> String? {
        guard line.hasPrefix("import ") else { return nil }
        return line.replacingOccurrences(of: "import ", with: "").trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Objective-C

    private func extractObjectiveCImport(_ line: String) -> String? {
        if line.hasPrefix("#import ") || line.hasPrefix("@import ") {
            let cleaned = line
                .replacingOccurrences(of: "#import ", with: "")
                .replacingOccurrences(of: "@import ", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "<>\""))
            if let framework = cleaned.components(separatedBy: "/").first {
                return framework.replacingOccurrences(of: ";", with: "").trimmingCharacters(in: .whitespaces)
            }
            return cleaned.replacingOccurrences(of: ";", with: "")
        }
        return nil
    }

    // MARK: - Python

    private func extractPythonImport(_ line: String) -> String? {
        if line.hasPrefix("import ") {
            return line.replacingOccurrences(of: "import ", with: "")
                .components(separatedBy: " as ").first?
                .components(separatedBy: ",").first?
                .trimmingCharacters(in: .whitespaces)
        }
        if line.hasPrefix("from ") {
            let parts = line.components(separatedBy: " import ")
            if let modulePart = parts.first {
                return modulePart.replacingOccurrences(of: "from ", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    // MARK: - JavaScript/TypeScript

    private func extractJSImport(_ line: String) -> String? {
        if line.contains("from '"), let result = extractBetween(line, start: "from '", end: "'") {
            return result
        }
        if line.contains("from \""), let result = extractBetween(line, start: "from \"", end: "\"") {
            return result
        }
        if line.contains("require('"), let result = extractBetween(line, start: "require('", end: "')") {
            return result
        }
        if line.contains("require(\""), let result = extractBetween(line, start: "require(\"", end: "\")") {
            return result
        }
        return nil
    }

    // MARK: - Java/Kotlin

    private func extractJavaImport(_ line: String) -> String? {
        guard line.hasPrefix("import ") else { return nil }
        return line.replacingOccurrences(of: "import ", with: "")
            .replacingOccurrences(of: "static ", with: "")
            .replacingOccurrences(of: ";", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Go

    private func extractGoImport(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
            return trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return nil
    }

    // MARK: - Rust

    private func extractRustImport(_ line: String) -> String? {
        if line.hasPrefix("use ") {
            return line.replacingOccurrences(of: "use ", with: "")
                .replacingOccurrences(of: ";", with: "")
                .components(separatedBy: "::").first?
                .trimmingCharacters(in: .whitespaces)
        }
        if line.hasPrefix("extern crate ") {
            return line.replacingOccurrences(of: "extern crate ", with: "")
                .replacingOccurrences(of: ";", with: "")
                .trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    // MARK: - C#

    private func extractCSharpImport(_ line: String) -> String? {
        guard line.hasPrefix("using ") && !line.contains("(") else { return nil }
        return line.replacingOccurrences(of: "using ", with: "")
            .replacingOccurrences(of: ";", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Ruby

    private func extractRubyImport(_ line: String) -> String? {
        if line.hasPrefix("require_relative ") {
            return line.replacingOccurrences(of: "require_relative ", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
        }
        if line.hasPrefix("require ") {
            return line.replacingOccurrences(of: "require ", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
        }
        return nil
    }

    // MARK: - PHP

    private func extractPHPImport(_ line: String) -> String? {
        if line.hasPrefix("use ") {
            return line.replacingOccurrences(of: "use ", with: "")
                .replacingOccurrences(of: ";", with: "")
                .components(separatedBy: " as ").first?
                .trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    // MARK: - C/C++

    private func extractCImport(_ line: String) -> String? {
        if line.hasPrefix("#include ") {
            let cleaned = line.replacingOccurrences(of: "#include ", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "<>\""))
            if let header = cleaned.components(separatedBy: "/").last {
                return header.replacingOccurrences(of: ".h", with: "")
                    .replacingOccurrences(of: ".hpp", with: "")
            }
        }
        return nil
    }

    // MARK: - Scala

    private func extractScalaImport(_ line: String) -> String? {
        guard line.hasPrefix("import ") else { return nil }
        return line.replacingOccurrences(of: "import ", with: "")
            .components(separatedBy: ".").first?
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Dart

    private func extractDartImport(_ line: String) -> String? {
        if line.hasPrefix("import '"), let result = extractBetween(line, start: "import '", end: "'") {
            return result.components(separatedBy: "/").last?.replacingOccurrences(of: ".dart", with: "")
        }
        return nil
    }

    // MARK: - R

    private func extractRImport(_ line: String) -> String? {
        if line.hasPrefix("library(") {
            return line.replacingOccurrences(of: "library(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        }
        if line.hasPrefix("require(") {
            return line.replacingOccurrences(of: "require(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        }
        return nil
    }

    // MARK: - Lua

    private func extractLuaImport(_ line: String) -> String? {
        if line.contains("require(") || line.contains("require \"") || line.contains("require '") {
            return line
                .replacingOccurrences(of: "require(", with: "")
                .replacingOccurrences(of: "require ", with: "")
                .replacingOccurrences(of: ")", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                .trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    // MARK: - Helper

    private func extractBetween(_ string: String, start: String, end: String) -> String? {
        guard let startRange = string.range(of: start),
              let endRange = string.range(of: end, range: startRange.upperBound..<string.endIndex) else {
            return nil
        }
        return String(string[startRange.upperBound..<endRange.lowerBound])
    }
}
