import Foundation

/// Value object representing supported programming languages
/// Following Open/Closed Principle - extensible for new languages
public enum ProgrammingLanguage: String, Sendable, Codable, CaseIterable {
    case swift
    case objectiveC = "objective-c"
    case typescript
    case javascript
    case python
    case kotlin
    case java
    case go
    case rust
    case unknown

    public var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .objectiveC: return "Objective-C"
        case .typescript: return "TypeScript"
        case .javascript: return "JavaScript"
        case .python: return "Python"
        case .kotlin: return "Kotlin"
        case .java: return "Java"
        case .go: return "Go"
        case .rust: return "Rust"
        case .unknown: return "Unknown"
        }
    }

    public var fileExtensions: [String] {
        switch self {
        case .swift: return ["swift"]
        case .objectiveC: return ["m", "mm", "h"]
        case .typescript: return ["ts", "tsx"]
        case .javascript: return ["js", "jsx"]
        case .python: return ["py"]
        case .kotlin: return ["kt", "kts"]
        case .java: return ["java"]
        case .go: return ["go"]
        case .rust: return ["rs"]
        case .unknown: return []
        }
    }

    public static func detectFromExtension(_ ext: String) -> ProgrammingLanguage? {
        for language in ProgrammingLanguage.allCases {
            if language.fileExtensions.contains(ext.lowercased()) {
                return language
            }
        }
        return nil
    }
}
