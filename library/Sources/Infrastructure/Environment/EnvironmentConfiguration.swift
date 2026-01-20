import Foundation

/// Environment configuration loader
/// Single Responsibility: Load environment configuration from .env file or process environment
public struct EnvironmentConfiguration: Sendable {
    // MARK: - Properties

    public let supabaseURL: URL
    public let supabaseAnonKey: String
    public let supabaseServiceRoleKey: String

    // MARK: - Initialization

    public init(
        supabaseURL: URL,
        supabaseAnonKey: String,
        supabaseServiceRoleKey: String
    ) {
        self.supabaseURL = supabaseURL
        self.supabaseAnonKey = supabaseAnonKey
        self.supabaseServiceRoleKey = supabaseServiceRoleKey
    }

    /// Load configuration from .env file
    public static func loadFromEnvFile(at path: String = ".env") throws -> Self {
        let fileURL = URL(fileURLWithPath: path)
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        var config: [String: String] = [:]

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            guard !trimmed.isEmpty,
                  !trimmed.hasPrefix("#") else {
                continue
            }

            // Parse KEY=VALUE
            let parts = trimmed.components(separatedBy: "=")
            guard parts.count == 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            config[key] = value
        }

        return try fromDictionary(config)
    }

    /// Load configuration from process environment
    public static func loadFromProcessEnvironment() throws -> Self {
        try fromDictionary(ProcessInfo.processInfo.environment)
    }

    // MARK: - Private Methods

    private static func fromDictionary(_ dict: [String: String]) throws -> Self {
        guard let urlString = dict["SUPABASE_URL"],
              let url = URL(string: urlString) else {
            throw EnvironmentError.missingRequiredKey("SUPABASE_URL")
        }

        guard let anonKey = dict["SUPABASE_ANON_KEY"] else {
            throw EnvironmentError.missingRequiredKey("SUPABASE_ANON_KEY")
        }

        guard let serviceRoleKey = dict["SUPABASE_SERVICE_ROLE_KEY"] else {
            throw EnvironmentError.missingRequiredKey("SUPABASE_SERVICE_ROLE_KEY")
        }

        return Self(
            supabaseURL: url,
            supabaseAnonKey: anonKey,
            supabaseServiceRoleKey: serviceRoleKey
        )
    }
}
