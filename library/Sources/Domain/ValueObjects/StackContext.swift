import Foundation

/// Tech stack context
/// Domain value object for technical stack information
public struct StackContext: Sendable, Codable {
    public let platform: Platform
    public let frameworks: [String]
    public let languages: [ProgrammingLanguage]
    public let architecture: ArchitecturePattern?

    public init(
        platform: Platform,
        frameworks: [String],
        languages: [ProgrammingLanguage],
        architecture: ArchitecturePattern? = nil
    ) {
        self.platform = platform
        self.frameworks = frameworks
        self.languages = languages
        self.architecture = architecture
    }

    /// Validate stack context
    /// - Throws: ValidationError if configuration is invalid
    public func validate() throws {
        try validateLanguages()
        try validateFrameworks()
        try checkDuplicates()
    }

    private func validateLanguages() throws {
        guard !languages.isEmpty else {
            throw ValidationError.missingRequired(field: "languages")
        }
    }

    private func validateFrameworks() throws {
        for framework in frameworks where framework.isEmpty {
            throw ValidationError.invalidFormat(
                field: "frameworks",
                expected: "non-empty strings"
            )
        }
    }

    private func checkDuplicates() throws {
        let languageSet = Set(languages.map { $0.rawValue })
        guard languageSet.count == languages.count else {
            throw ValidationError.custom(
                "Duplicate languages detected"
            )
        }

        let frameworkSet = Set(frameworks)
        guard frameworkSet.count == frameworks.count else {
            throw ValidationError.custom(
                "Duplicate frameworks detected"
            )
        }
    }
}
