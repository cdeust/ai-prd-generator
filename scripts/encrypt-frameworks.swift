#!/usr/bin/env swift
// encrypt-frameworks.swift — Encrypt XCFrameworks with license key + hardware fingerprint
// Must be compiled: swiftc -o /tmp/encrypt-frameworks scripts/encrypt-frameworks.swift -framework IOKit
// Usage: /tmp/encrypt-frameworks

import CryptoKit
import Foundation

#if os(macOS)
import IOKit
#endif

// MARK: - Standalone copies of encryption types (for script use)

let magicHeader = Data("AIPRD-ENC-V1".utf8)

func generateHardwareFingerprint() -> String {
    var components: [String] = []
    #if os(macOS)
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
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &model, &size, nil, 0)
    components.append("MODEL:\(String(cString: model))")
    #endif
    if components.isEmpty {
        components.append("HOST:\(ProcessInfo.processInfo.hostName):\(NSUserName())")
    }
    let combined = components.joined(separator: "|")
    let hash = SHA256.hash(data: Data(combined.utf8))
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}

func deriveKey(licenseKey: String, hardwareFingerprint: String) -> SymmetricKey {
    let inputKeyMaterial = Data((licenseKey + ":" + hardwareFingerprint).utf8)
    let salt = Data("AIPRD-SALT-2026".utf8)
    let info = Data("framework-encryption".utf8)
    return HKDF<SHA256>.deriveKey(
        inputKeyMaterial: SymmetricKey(data: inputKeyMaterial),
        salt: salt,
        info: info,
        outputByteCount: 32
    )
}

func encryptData(_ data: Data, key: SymmetricKey) throws -> Data {
    let nonce = AES.GCM.Nonce()
    let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
    var encrypted = Data()
    encrypted.append(magicHeader)
    encrypted.append(contentsOf: nonce)
    encrypted.append(sealedBox.ciphertext)
    encrypted.append(sealedBox.tag)
    return encrypted
}

// MARK: - Main

let aiprdDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".aiprd")
let licensePath = aiprdDir.appendingPathComponent("license.json")

// Determine paths relative to script location
let repoRoot: URL
if let env = ProcessInfo.processInfo.environment["REPO_ROOT"] {
    repoRoot = URL(fileURLWithPath: env)
} else {
    repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
}

let xcframeworksDir = repoRoot.appendingPathComponent("build/xcframeworks")
let encryptedDir = repoRoot.appendingPathComponent("build/encrypted-xcframeworks")

print("═══════════════════════════════════════════════════════")
print("  AIPRD Framework Encryption")
print("═══════════════════════════════════════════════════════")
print("")

// Load license
guard FileManager.default.fileExists(atPath: licensePath.path) else {
    print("❌ License not found at: \(licensePath.path)")
    print("   Run generate-license.swift first.")
    exit(1)
}

let licenseData = try Data(contentsOf: licensePath)
let license = try JSONSerialization.jsonObject(with: licenseData) as! [String: Any]
let licenseId = license["license_id"] as! String
let hwFingerprint = license["hardware_fingerprint"] as? String ?? generateHardwareFingerprint()

print("  License: \(licenseId)")
print("  Hardware: \(hwFingerprint.prefix(16))...")
print("")

// Derive encryption key
let key = deriveKey(licenseKey: licenseId, hardwareFingerprint: hwFingerprint)

// Find xcframeworks
guard FileManager.default.fileExists(atPath: xcframeworksDir.path) else {
    print("❌ XCFrameworks directory not found: \(xcframeworksDir.path)")
    print("   Run build-xcframeworks.sh first.")
    exit(1)
}

try FileManager.default.createDirectory(at: encryptedDir, withIntermediateDirectories: true)

let contents = try FileManager.default.contentsOfDirectory(
    at: xcframeworksDir,
    includingPropertiesForKeys: nil
)
let frameworks = contents.filter { $0.pathExtension == "xcframework" }

if frameworks.isEmpty {
    print("⚠️  No .xcframework files found in: \(xcframeworksDir.path)")
    exit(1)
}

var successCount = 0
for frameworkURL in frameworks {
    let name = frameworkURL.deletingPathExtension().lastPathComponent
    print("  Encrypting: \(name)...")

    // Read the entire xcframework as a tar archive for encryption
    // First, tar the xcframework directory
    let tarPath = encryptedDir.appendingPathComponent("\(name).xcframework.tar")
    let tarProcess = Process()
    tarProcess.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
    tarProcess.arguments = ["-cf", tarPath.path, "-C", xcframeworksDir.path, "\(name).xcframework"]
    try tarProcess.run()
    tarProcess.waitUntilExit()

    guard tarProcess.terminationStatus == 0 else {
        print("    ❌ Failed to tar \(name)")
        continue
    }

    // Read tar data
    let tarData = try Data(contentsOf: tarPath)

    // Encrypt
    let encrypted = try encryptData(tarData, key: key)

    // Write encrypted file
    let encryptedPath = encryptedDir.appendingPathComponent("\(name).xcframework")
    try encrypted.write(to: encryptedPath)

    // Verify magic header
    let verify = try Data(contentsOf: encryptedPath)
    let hasHeader = verify.prefix(magicHeader.count) == magicHeader
    let sizeKB = encrypted.count / 1024

    // Clean up tar
    try? FileManager.default.removeItem(at: tarPath)

    print("    ✅ Encrypted: \(sizeKB) KB, header valid: \(hasHeader)")
    successCount += 1
}

print("")
print("═══════════════════════════════════════════════════════")
print("  Encryption Summary")
print("═══════════════════════════════════════════════════════")
print("  ✅ Encrypted: \(successCount) / \(frameworks.count) frameworks")
print("  Output: \(encryptedDir.path)")
print("")

// List encrypted files
let encryptedFiles = try FileManager.default.contentsOfDirectory(
    at: encryptedDir,
    includingPropertiesForKeys: [.fileSizeKey]
)
for file in encryptedFiles.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
    let attrs = try FileManager.default.attributesOfItem(atPath: file.path)
    let size = (attrs[.size] as? Int ?? 0) / 1024
    print("  \(file.lastPathComponent) (\(size) KB)")
}
print("═══════════════════════════════════════════════════════")
