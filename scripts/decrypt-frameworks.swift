#!/usr/bin/env swift
// decrypt-frameworks.swift — Decrypt encrypted XCFrameworks for local building
// Compiled by setup-frameworks.sh

import CryptoKit
import Foundation

#if os(macOS)
import IOKit
#endif

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
            platformExpert, kIOPlatformSerialNumberKey as CFString,
            kCFAllocatorDefault, 0
        )?.takeUnretainedValue() as? String {
            components.append("SN:\(serial)")
        }
        if let uuid = IORegistryEntryCreateCFProperty(
            platformExpert, kIOPlatformUUIDKey as CFString,
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
        salt: salt, info: info, outputByteCount: 32
    )
}

func decryptData(_ encryptedData: Data, key: SymmetricKey) throws -> Data {
    guard encryptedData.count > magicHeader.count + 12 + 16 else {
        throw NSError(domain: "AIPRD", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid format"])
    }
    guard encryptedData.prefix(magicHeader.count) == magicHeader else {
        throw NSError(domain: "AIPRD", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid header"])
    }
    let nonceStart = magicHeader.count
    let nonceEnd = nonceStart + 12
    let tagStart = encryptedData.count - 16
    let nonce = try AES.GCM.Nonce(data: encryptedData[nonceStart..<nonceEnd])
    let sealedBox = try AES.GCM.SealedBox(
        nonce: nonce,
        ciphertext: encryptedData[nonceEnd..<tagStart],
        tag: encryptedData[tagStart...]
    )
    return try AES.GCM.open(sealedBox, using: key)
}

// MARK: - Main

let licensePath = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".aiprd/license.json")

let encryptedDir: URL
let outputDir: URL

if let env = ProcessInfo.processInfo.environment["ENCRYPTED_DIR"] {
    encryptedDir = URL(fileURLWithPath: env)
} else {
    encryptedDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("frameworks/encrypted")
}

if let env = ProcessInfo.processInfo.environment["OUTPUT_DIR"] {
    outputDir = URL(fileURLWithPath: env)
} else {
    outputDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("frameworks")
}

// Load license
let licenseData = try Data(contentsOf: licensePath)
let license = try JSONSerialization.jsonObject(with: licenseData) as! [String: Any]
let licenseId = license["license_id"] as! String
let hwFingerprint = license["hardware_fingerprint"] as? String ?? generateHardwareFingerprint()

// Verify hardware
let currentHW = generateHardwareFingerprint()
guard hwFingerprint == currentHW else {
    print("❌ License is bound to different hardware")
    print("   License HW: \(hwFingerprint.prefix(16))...")
    print("   Current HW: \(currentHW.prefix(16))...")
    exit(1)
}

let key = deriveKey(licenseKey: licenseId, hardwareFingerprint: hwFingerprint)

// Source packages output directory
let packagesDir: URL
if let env = ProcessInfo.processInfo.environment["PACKAGES_DIR"] {
    packagesDir = URL(fileURLWithPath: env)
} else {
    packagesDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("packages")
}

// Decrypt each framework
let contents = try FileManager.default.contentsOfDirectory(
    at: encryptedDir, includingPropertiesForKeys: nil
)
let encrypted = contents.filter { $0.pathExtension == "xcframework" }

var success = 0
for file in encrypted.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
    let name = file.deletingPathExtension().lastPathComponent
    print("  Decrypting: \(name)...")

    let data = try Data(contentsOf: file)
    let decrypted = try decryptData(data, key: key)

    // Decrypted data is a tar archive — extract it
    let tarPath = outputDir.appendingPathComponent("\(name).tar")
    try decrypted.write(to: tarPath)

    let extractDir = outputDir
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
    process.arguments = ["-xf", tarPath.path, "-C", extractDir.path]
    try process.run()
    process.waitUntilExit()

    try? FileManager.default.removeItem(at: tarPath)

    if process.terminationStatus == 0 {
        print("    ✅ \(name).xcframework")
        success += 1
    } else {
        print("    ❌ Failed to extract \(name)")
    }
}

// Decrypt source packages
let sourcePackages = contents.filter { $0.pathExtension == "source-package" }
for file in sourcePackages.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
    let name = file.deletingPathExtension().lastPathComponent
    print("  Decrypting source: \(name)...")

    let data = try Data(contentsOf: file)
    let decrypted = try decryptData(data, key: key)

    // Decrypted data is a tar archive of the package source
    try FileManager.default.createDirectory(at: packagesDir, withIntermediateDirectories: true)
    let tarPath = packagesDir.appendingPathComponent("\(name).tar")
    try decrypted.write(to: tarPath)

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
    process.arguments = ["-xf", tarPath.path, "-C", packagesDir.path]
    try process.run()
    process.waitUntilExit()

    try? FileManager.default.removeItem(at: tarPath)

    if process.terminationStatus == 0 {
        print("    ✅ \(name) (source)")
        success += 1
    } else {
        print("    ❌ Failed to extract \(name)")
    }
}

let totalItems = encrypted.count + sourcePackages.count
print("")
print("  Decrypted: \(success) / \(totalItems) items (\(encrypted.count) frameworks, \(sourcePackages.count) source packages)")
