#!/usr/bin/env swift
// validate-license.swift — Cryptographic license validation CLI
//
// Standalone binary that performs the same Ed25519 + HMAC + hardware
// validation as CryptoLicenseValidationAdapter. Outputs JSON to stdout
// so that prompt-based skills (SKILL.md) can call it via Bash and parse
// the result instead of doing their own insecure file reading.
//
// Build:  swiftc -o ~/.aiprd/validate-license validate-license.swift -framework IOKit
// Usage:  ~/.aiprd/validate-license
//
// The public key placeholder is patched by inject-public-key.sh at build time.

import CryptoKit
import Foundation

#if os(macOS)
import IOKit
#endif

// ============================================================================
// MARK: - Configuration
// ============================================================================

/// Ed25519 public key for verifying license signatures
/// Replaced at build time by `scripts/distribution/inject-public-key.sh`
let publicKeyBase64 = "SEWbJLQAKrNKkm4N3l5sIEPv7KHTQFEIZJ1fU7+pdd8="

let licensePrimaryPath = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".aiprd/license.json")
let licenseLegacyPath = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".ai-prd/license.json")
let trialPath = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".aiprd/trial.json")
let trialDurationDays = 14

// ============================================================================
// MARK: - Hardware Fingerprint (mirrors HardwareFingerprint.swift)
// ============================================================================

func generateHardwareFingerprint() -> String {
    var components: [String] = []

    #if os(macOS)
    if let serial = getMacSerialNumber() {
        components.append("SN:\(serial)")
    }
    if let uuid = getMacHardwareUUID() {
        components.append("UUID:\(uuid)")
    }
    if let model = getMacModelIdentifier() {
        components.append("MODEL:\(model)")
    }
    #endif

    if components.isEmpty {
        let hostname = ProcessInfo.processInfo.hostName
        let user = NSUserName()
        components.append("HOST:\(hostname):\(user)")
    }

    let combined = components.joined(separator: "|")
    let hash = SHA256.hash(data: Data(combined.utf8))
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}

#if os(macOS)
func getMacSerialNumber() -> String? {
    let expert = IOServiceGetMatchingService(
        kIOMainPortDefault,
        IOServiceMatching("IOPlatformExpertDevice")
    )
    guard expert != 0 else { return nil }
    defer { IOObjectRelease(expert) }
    return IORegistryEntryCreateCFProperty(
        expert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0
    )?.takeUnretainedValue() as? String
}

func getMacHardwareUUID() -> String? {
    let expert = IOServiceGetMatchingService(
        kIOMainPortDefault,
        IOServiceMatching("IOPlatformExpertDevice")
    )
    guard expert != 0 else { return nil }
    defer { IOObjectRelease(expert) }
    return IORegistryEntryCreateCFProperty(
        expert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0
    )?.takeUnretainedValue() as? String
}

func getMacModelIdentifier() -> String? {
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &model, &size, nil, 0)
    return String(cString: model)
}
#endif

// ============================================================================
// MARK: - License File Model (mirrors UnifiedLicenseFile.swift)
// ============================================================================

struct LicenseFile: Codable {
    let licenseId: String
    let issuedTo: String
    let issuedAt: Date
    let expiresAt: Date?
    let tier: String
    let enabledFeatures: [String]
    let hardwareFingerprint: String?
    let signature: String

    enum CodingKeys: String, CodingKey {
        case licenseId = "license_id"
        case issuedTo = "issued_to"
        case issuedAt = "issued_at"
        case expiresAt = "expires_at"
        case tier
        case enabledFeatures = "enabled_features"
        case hardwareFingerprint = "hardware_fingerprint"
        case signature
    }
}

// ============================================================================
// MARK: - Trial File Model (mirrors TrialLicenseManager.TrialFile)
// ============================================================================

struct TrialFile: Codable {
    let trialStartedAt: Date
    let trialExpiresAt: Date
    let hardwareFingerprint: String
    let hmac: String

    enum CodingKeys: String, CodingKey {
        case trialStartedAt = "trial_started_at"
        case trialExpiresAt = "trial_expires_at"
        case hardwareFingerprint = "hardware_fingerprint"
        case hmac
    }
}

// ============================================================================
// MARK: - Output Model
// ============================================================================

struct ValidationResult: Codable {
    let tier: String
    let features: [String]
    let signatureVerified: Bool
    let hardwareVerified: Bool
    let expiresAt: String?
    let daysRemaining: Int?
    let source: String
    let errors: [String]

    enum CodingKeys: String, CodingKey {
        case tier
        case features
        case signatureVerified = "signature_verified"
        case hardwareVerified = "hardware_verified"
        case expiresAt = "expires_at"
        case daysRemaining = "days_remaining"
        case source
        case errors
    }
}

// ============================================================================
// MARK: - Ed25519 Signature Verification (mirrors SecureLicenseValidator)
// ============================================================================

func createSignedPayload(_ license: LicenseFile) -> Data {
    var payload = ""
    payload += "ID:\(license.licenseId)|"
    payload += "TO:\(license.issuedTo)|"
    payload += "AT:\(license.issuedAt.ISO8601Format())|"
    if let expires = license.expiresAt {
        payload += "EXP:\(expires.ISO8601Format())|"
    }
    payload += "TIER:\(license.tier)|"
    if let hwid = license.hardwareFingerprint {
        payload += "HWID:\(hwid)|"
    }
    payload += "FEATURES:\(license.enabledFeatures.sorted().joined(separator: ","))"
    return Data(payload.utf8)
}

func verifySignature(_ license: LicenseFile) -> Bool {
    let signedData = createSignedPayload(license)
    guard let signatureData = Data(base64Encoded: license.signature) else { return false }

    do {
        guard let publicKeyData = Data(base64Encoded: publicKeyBase64) else { return false }
        let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
        return publicKey.isValidSignature(signatureData, for: signedData)
    } catch {
        return false
    }
}

// ============================================================================
// MARK: - HMAC Verification (mirrors TrialLicenseManager)
// ============================================================================

func computeTrialHMAC(startedAt: Date, expiresAt: Date, hardware: String) -> String {
    let payload = "TRIAL|START:\(startedAt.ISO8601Format())|EXP:\(expiresAt.ISO8601Format())"
    let key = SymmetricKey(data: Data(hardware.utf8))
    let mac = HMAC<SHA256>.authenticationCode(for: Data(payload.utf8), using: key)
    return Data(mac).base64EncodedString()
}

// ============================================================================
// MARK: - License Resolution
// ============================================================================

func daysUntil(_ date: Date) -> Int {
    let calendar = Calendar.current
    let now = calendar.startOfDay(for: Date())
    let target = calendar.startOfDay(for: date)
    return calendar.dateComponents([.day], from: now, to: target).day ?? 0
}

func resolveFromSignedLicense() -> ValidationResult? {
    let searchPaths = [licensePrimaryPath, licenseLegacyPath]

    for path in searchPaths {
        guard FileManager.default.fileExists(atPath: path.path) else { continue }

        do {
            let data = try Data(contentsOf: path)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let license = try decoder.decode(LicenseFile.self, from: data)

            var errors: [String] = []

            // 1. Check expiration
            if let expiresAt = license.expiresAt, Date() > expiresAt {
                errors.append("License expired")
            }

            // 2. Verify hardware binding
            let currentHW = generateHardwareFingerprint()
            let hwVerified: Bool
            if let boundHW = license.hardwareFingerprint {
                hwVerified = boundHW == currentHW
                if !hwVerified {
                    errors.append("Hardware fingerprint mismatch")
                }
            } else {
                hwVerified = true
            }

            // 3. Verify Ed25519 signature
            let sigVerified = verifySignature(license)
            if !sigVerified {
                errors.append("Invalid signature")
            }

            if errors.isEmpty {
                let daysLeft = license.expiresAt.map { daysUntil($0) }
                return ValidationResult(
                    tier: license.tier,
                    features: license.enabledFeatures,
                    signatureVerified: true,
                    hardwareVerified: hwVerified,
                    expiresAt: license.expiresAt?.ISO8601Format(),
                    daysRemaining: daysLeft,
                    source: "signed_license_file",
                    errors: []
                )
            }
        } catch {
            continue
        }
    }
    return nil
}

func resolveFromTrial() -> ValidationResult? {
    guard FileManager.default.fileExists(atPath: trialPath.path) else { return nil }

    do {
        let data = try Data(contentsOf: trialPath)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let trial = try decoder.decode(TrialFile.self, from: data)

        // 1. Verify hardware
        let currentHW = generateHardwareFingerprint()
        guard trial.hardwareFingerprint == currentHW else {
            return nil
        }

        // 2. Verify HMAC
        let expectedHMAC = computeTrialHMAC(
            startedAt: trial.trialStartedAt,
            expiresAt: trial.trialExpiresAt,
            hardware: trial.hardwareFingerprint
        )
        guard trial.hmac == expectedHMAC else {
            return nil
        }

        // 3. Check expiry
        guard Date() <= trial.trialExpiresAt else {
            return nil
        }

        let daysLeft = daysUntil(trial.trialExpiresAt)
        return ValidationResult(
            tier: "trial",
            features: allLicensedFeatures(),
            signatureVerified: false,
            hardwareVerified: true,
            expiresAt: trial.trialExpiresAt.ISO8601Format(),
            daysRemaining: daysLeft,
            source: "trial",
            errors: []
        )
    } catch {
        return nil
    }
}

func createAndResolveTrial() -> ValidationResult? {
    // Don't overwrite existing trial
    guard !FileManager.default.fileExists(atPath: trialPath.path) else { return nil }

    let hwFingerprint = generateHardwareFingerprint()
    let now = Date()
    guard let expiresAt = Calendar.current.date(
        byAdding: .day, value: trialDurationDays, to: now
    ) else { return nil }

    let hmac = computeTrialHMAC(startedAt: now, expiresAt: expiresAt, hardware: hwFingerprint)

    let trial = TrialFile(
        trialStartedAt: now,
        trialExpiresAt: expiresAt,
        hardwareFingerprint: hwFingerprint,
        hmac: hmac
    )

    do {
        let directory = trialPath.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(trial)
        try data.write(to: trialPath, options: .atomic)

        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: trialPath.path
        )

        let daysLeft = daysUntil(expiresAt)
        return ValidationResult(
            tier: "trial",
            features: allLicensedFeatures(),
            signatureVerified: false,
            hardwareVerified: true,
            expiresAt: expiresAt.ISO8601Format(),
            daysRemaining: daysLeft,
            source: "trial_created",
            errors: []
        )
    } catch {
        return nil
    }
}

func allLicensedFeatures() -> [String] {
    return [
        "thinking_strategies",
        "advanced_rag",
        "verification_engine",
        "vision_engine",
        "orchestration_engine",
        "encryption_engine",
        "strategy_engine"
    ]
}

func freeResult(errors: [String] = []) -> ValidationResult {
    return ValidationResult(
        tier: "free",
        features: [],
        signatureVerified: false,
        hardwareVerified: false,
        expiresAt: nil,
        daysRemaining: nil,
        source: "default_free",
        errors: errors
    )
}

// ============================================================================
// MARK: - Main
// ============================================================================

func main() {
    // Resolution chain (same as CryptoLicenseValidationAdapter):
    // 1. Signed license file (Ed25519 + hardware + expiry)
    // 2. Trial license (HMAC + hardware + expiry)
    // 3. Auto-create trial for first-time users
    // 4. Default to free

    let result: ValidationResult

    if let signed = resolveFromSignedLicense() {
        result = signed
    } else if let trial = resolveFromTrial() {
        result = trial
    } else if let newTrial = createAndResolveTrial() {
        result = newTrial
    } else {
        result = freeResult()
    }

    // Output JSON to stdout
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(result),
       let json = String(data: data, encoding: .utf8) {
        print(json)
    } else {
        // Fallback: minimal free-tier JSON
        print("""
        {"tier":"free","features":[],"signature_verified":false,"hardware_verified":false,"source":"error","errors":["JSON encoding failed"]}
        """)
    }
}

main()
