import AIPRDEncryptionEngine
import AIPRDSharedUtilities
import Foundation

/// Factory for creating license validation infrastructure
/// Wires the CryptoLicenseValidationAdapter (EncryptionEngine) to the LicenseValidationPort (SharedUtilities)
public enum LicenseFactory {

    /// Create the cryptographic license validator
    public static func createValidator() -> LicenseValidationPort {
        CryptoLicenseValidationAdapter()
    }

    /// Resolve the current license tier using cryptographic validation
    public static func resolveLicenseTier() -> LicenseResolution {
        createValidator().resolveLicenseTier()
    }

    /// Load the raw license file for consumers that need the full object
    /// (e.g., SecureFrameworkLoader for decryption key derivation)
    /// Returns nil if no valid license file is found
    public static func loadLicenseFile() -> UnifiedLicenseFile? {
        for path in LicenseFileLocations.searchPaths {
            if let license = SecureLicenseValidator.loadLicenseFile(from: path),
               SecureLicenseValidator.loadAndValidate(from: path).isValid {
                return license
            }
        }
        return nil
    }
}
