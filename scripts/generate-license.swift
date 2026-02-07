#!/usr/bin/env swift
// generate-license.swift — Generate a hardware-bound signed license for this Mac
// Must be compiled: swiftc -o /tmp/generate-license scripts/generate-license.swift
// Usage: /tmp/generate-license

import CryptoKit
import Foundation

#if os(macOS)
import IOKit
#endif

// MARK: - Hardware Fingerprint (standalone copy for script use)

func generateHardwareFingerprint() -> String {
    var components: [String] = []

    #if os(macOS)
    // Serial number
    let platformExpert = IOServiceGetMatchingService(
        kIOMainPortDefault,
        IOServiceMatching("IOPlatformExpertDevice")
    )
    if platformExpert != 0 {
        defer { IOObjectRelease(platformExpert) }
        if let serial = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformSerialNumberKey as CFString,
            kCFAllocatorDefault, 0
        )?.takeUnretainedValue() as? String {
            components.append("SN:\(serial)")
        }
        if let uuid = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault, 0
        )?.takeUnretainedValue() as? String {
            components.append("UUID:\(uuid)")
        }
    }
    // Model identifier
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &model, &size, nil, 0)
    components.append("MODEL:\(String(cString: model))")
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

// MARK: - License Payload + Signing

struct LicenseData: Codable {
    let license_id: String
    let issued_to: String
    let issued_at: String
    let expires_at: String?
    let tier: String
    let enabled_features: [String]
    let hardware_fingerprint: String?
    let signature: String
}

func createSignedPayload(
    licenseId: String,
    issuedTo: String,
    issuedAt: Date,
    expiresAt: Date?,
    tier: String,
    enabledFeatures: [String],
    hardwareFingerprint: String?
) -> Data {
    let formatter = ISO8601DateFormatter()
    var payload = ""
    payload += "ID:\(licenseId)|"
    payload += "TO:\(issuedTo)|"
    payload += "AT:\(formatter.string(from: issuedAt))|"
    if let expires = expiresAt {
        payload += "EXP:\(formatter.string(from: expires))|"
    }
    payload += "TIER:\(tier)|"
    if let hwid = hardwareFingerprint {
        payload += "HWID:\(hwid)|"
    }
    payload += "FEATURES:\(enabledFeatures.sorted().joined(separator: ","))"
    return Data(payload.utf8)
}

// MARK: - Main

let aiprdDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".aiprd")
let privateKeyPath = aiprdDir.appendingPathComponent("private-key.pem")
let licensePath = aiprdDir.appendingPathComponent("license.json")

// Load private key
guard FileManager.default.fileExists(atPath: privateKeyPath.path) else {
    print("❌ Private key not found at: \(privateKeyPath.path)")
    print("   Run generate-keypair.swift first.")
    exit(1)
}

let privateKeyBase64 = try String(contentsOf: privateKeyPath, encoding: .utf8)
    .trimmingCharacters(in: .whitespacesAndNewlines)
guard let privateKeyData = Data(base64Encoded: privateKeyBase64) else {
    print("❌ Failed to decode private key from base64")
    exit(1)
}
let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)

// Generate license data
let licenseId = "AIPRD-\(UUID().uuidString.prefix(8).uppercased())"
let issuedTo = "clement.deust@proton.me"
let issuedAt = Date()
let tier = "licensed"
let hardwareFingerprint = generateHardwareFingerprint()
let enabledFeatures = [
    "thinking_strategies",
    "advanced_rag",
    "verification_engine",
    "vision_engine",
    "orchestration_engine",
    "encryption_engine",
    "strategy_engine"
]

// Sign
let payload = createSignedPayload(
    licenseId: licenseId,
    issuedTo: issuedTo,
    issuedAt: issuedAt,
    expiresAt: nil,
    tier: tier,
    enabledFeatures: enabledFeatures,
    hardwareFingerprint: hardwareFingerprint
)
let signature = try privateKey.signature(for: payload)
let signatureBase64 = Data(signature).base64EncodedString()

// Build license JSON
let formatter = ISO8601DateFormatter()
let license = LicenseData(
    license_id: licenseId,
    issued_to: issuedTo,
    issued_at: formatter.string(from: issuedAt),
    expires_at: nil,
    tier: tier,
    enabled_features: enabledFeatures,
    hardware_fingerprint: hardwareFingerprint,
    signature: signatureBase64
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let jsonData = try encoder.encode(license)
try jsonData.write(to: licensePath)

// Restrict permissions
try FileManager.default.setAttributes(
    [.posixPermissions: 0o600],
    ofItemAtPath: licensePath.path
)

// Verify the signature we just created
let publicKey = privateKey.publicKey
let isValid = publicKey.isValidSignature(signature, for: payload)

print("✅ License generated successfully")
print("")
print("   License ID:    \(licenseId)")
print("   Issued to:     \(issuedTo)")
print("   Tier:          \(tier)")
print("   Hardware:      \(hardwareFingerprint.prefix(16))...")
print("   Features:      \(enabledFeatures.count) enabled")
print("   Expires:       Never (perpetual)")
print("   Signature:     \(signatureBase64.prefix(32))...")
print("   Sig valid:     \(isValid)")
print("")
print("   Saved to: \(licensePath.path)")
