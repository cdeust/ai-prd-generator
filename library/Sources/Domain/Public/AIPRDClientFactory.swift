import Foundation

/// Factory for creating AI PRD clients
/// Public factory for client instantiation
public enum AIPRDClientFactory {
    /// Create a new AI PRD client
    /// - Parameter configuration: Client configuration
    /// - Returns: Configured client instance
    public static func create(configuration: AIPRDConfiguration) -> AIPRDClient {
        // Implementation will be in Application/Infrastructure layers
        // This is just the public interface
        fatalError("Implementation provided by Application layer")
    }
}
