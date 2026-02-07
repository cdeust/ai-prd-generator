#!/usr/bin/env swift
// test-encryption.swift — End-to-end test of the encrypt/decrypt/validate pipeline
// Must be compiled: swiftc -o /tmp/test-encryption scripts/test-encryption.swift -framework IOKit
// Usage: /tmp/test-encryption

import CryptoKit
import Foundation

#if os(macOS)
import IOKit
#endif

// MARK: - Standalone copies (for script use)

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

func decryptData(_ encryptedData: Data, key: SymmetricKey) throws -> Data {
    guard encryptedData.count > magicHeader.count + 12 + 16 else {
        throw TestError.invalidFormat
    }
    let headerRange = 0..<magicHeader.count
    guard encryptedData[headerRange] == magicHeader else {
        throw TestError.invalidHeader
    }
    let nonceStart = magicHeader.count
    let nonceEnd = nonceStart + 12
    let nonceData = encryptedData[nonceStart..<nonceEnd]
    let tagStart = encryptedData.count - 16
    let ciphertext = encryptedData[nonceEnd..<tagStart]
    let tag = encryptedData[tagStart...]
    let nonce = try AES.GCM.Nonce(data: nonceData)
    let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
    return try AES.GCM.open(sealedBox, using: key)
}

enum TestError: Error {
    case invalidFormat
    case invalidHeader
}

func createSignedPayload(
    licenseId: String,
    issuedTo: String,
    issuedAt: String,
    expiresAt: String?,
    tier: String,
    features: [String],
    hardwareFingerprint: String?
) -> Data {
    var payload = ""
    payload += "ID:\(licenseId)|"
    payload += "TO:\(issuedTo)|"
    payload += "AT:\(issuedAt)|"
    if let expires = expiresAt {
        payload += "EXP:\(expires)|"
    }
    payload += "TIER:\(tier)|"
    if let hwid = hardwareFingerprint {
        payload += "HWID:\(hwid)|"
    }
    payload += "FEATURES:\(features.sorted().joined(separator: ","))"
    return Data(payload.utf8)
}

// MARK: - Tests

var passed = 0
var failed = 0

func test(_ name: String, _ block: () throws -> Bool) {
    do {
        if try block() {
            print("  ✅ PASS: \(name)")
            passed += 1
        } else {
            print("  ❌ FAIL: \(name)")
            failed += 1
        }
    } catch {
        print("  ❌ FAIL: \(name) — \(error)")
        failed += 1
    }
}

print("═══════════════════════════════════════════════════════")
print("  AIPRD Encryption Pipeline Tests")
print("═══════════════════════════════════════════════════════")
print("")

// --- Test 1: Hardware fingerprint stability ---
print("  [Hardware Fingerprint]")
test("Fingerprint is 64-char hex") {
    let fp = generateHardwareFingerprint()
    return fp.count == 64 && fp.allSatisfy { $0.isHexDigit }
}
test("Fingerprint is stable across calls") {
    let fp1 = generateHardwareFingerprint()
    let fp2 = generateHardwareFingerprint()
    return fp1 == fp2
}
print("")

// --- Test 2: License validation ---
print("  [License Validation]")
let aiprdDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".aiprd")
let licensePath = aiprdDir.appendingPathComponent("license.json")
let privateKeyPath = aiprdDir.appendingPathComponent("private-key.pem")

test("License file exists") {
    return FileManager.default.fileExists(atPath: licensePath.path)
}

let licenseData = try Data(contentsOf: licensePath)
let licenseJSON = try JSONSerialization.jsonObject(with: licenseData) as! [String: Any]
let licenseId = licenseJSON["license_id"] as! String
let issuedTo = licenseJSON["issued_to"] as! String
let issuedAt = licenseJSON["issued_at"] as! String
let tier = licenseJSON["tier"] as! String
let features = licenseJSON["enabled_features"] as! [String]
let hwFingerprint = licenseJSON["hardware_fingerprint"] as? String
let signatureBase64 = licenseJSON["signature"] as! String

test("License tier is 'licensed'") {
    return tier == "licensed"
}
test("License has 7 features") {
    return features.count == 7
}
test("License is hardware-bound") {
    return hwFingerprint != nil
}
test("Hardware fingerprint matches this machine") {
    let current = generateHardwareFingerprint()
    return hwFingerprint == current
}

// Verify signature
test("Ed25519 signature is valid") {
    let privateKeyBase64 = try String(contentsOf: privateKeyPath, encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let privateKeyData = Data(base64Encoded: privateKeyBase64) else { return false }
    let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
    let publicKey = privateKey.publicKey

    let payload = createSignedPayload(
        licenseId: licenseId,
        issuedTo: issuedTo,
        issuedAt: issuedAt,
        expiresAt: nil,
        tier: tier,
        features: features,
        hardwareFingerprint: hwFingerprint
    )

    guard let sigData = Data(base64Encoded: signatureBase64) else { return false }
    return publicKey.isValidSignature(sigData, for: payload)
}
print("")

// --- Test 3: Encrypt/Decrypt cycle ---
print("  [Encrypt/Decrypt Cycle]")
let testData = Data("Hello, this is a test framework binary content for AIPRD encryption verification.".utf8)
let testKey = deriveKey(licenseKey: licenseId, hardwareFingerprint: hwFingerprint ?? "test")

test("Encrypt produces data with magic header") {
    let encrypted = try encryptData(testData, key: testKey)
    return encrypted.prefix(magicHeader.count) == magicHeader
}

test("Decrypt recovers original data") {
    let encrypted = try encryptData(testData, key: testKey)
    let decrypted = try decryptData(encrypted, key: testKey)
    return decrypted == testData
}

test("Wrong key fails to decrypt") {
    let encrypted = try encryptData(testData, key: testKey)
    let wrongKey = deriveKey(licenseKey: "WRONG-LICENSE", hardwareFingerprint: "wrong-hw")
    do {
        _ = try decryptData(encrypted, key: wrongKey)
        return false // Should have thrown
    } catch {
        return true // Expected failure
    }
}

test("Wrong hardware fingerprint produces different key") {
    let key1 = deriveKey(licenseKey: licenseId, hardwareFingerprint: "hardware-A")
    let key2 = deriveKey(licenseKey: licenseId, hardwareFingerprint: "hardware-B")
    // Encrypt with key1, attempt decrypt with key2
    let encrypted = try encryptData(testData, key: key1)
    do {
        _ = try decryptData(encrypted, key: key2)
        return false
    } catch {
        return true
    }
}

test("Corrupted data fails with invalidFormat") {
    do {
        _ = try decryptData(Data([0x00, 0x01, 0x02]), key: testKey)
        return false
    } catch TestError.invalidFormat {
        return true
    } catch {
        return false
    }
}

test("Wrong magic header fails") {
    var bad = Data("WRONG-HEADER".utf8)
    bad.append(Data(repeating: 0, count: 100))
    do {
        _ = try decryptData(bad, key: testKey)
        return false
    } catch TestError.invalidHeader {
        return true
    } catch {
        return false
    }
}

test("Large data encrypt/decrypt (1 MB)") {
    let largeData = Data((0..<1_000_000).map { UInt8($0 % 256) })
    let encrypted = try encryptData(largeData, key: testKey)
    let decrypted = try decryptData(encrypted, key: testKey)
    return decrypted == largeData
}
print("")

// --- Test 4: Encrypted frameworks (if available) ---
let repoRoot: URL
if let env = ProcessInfo.processInfo.environment["REPO_ROOT"] {
    repoRoot = URL(fileURLWithPath: env)
} else {
    repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
}
let encryptedDir = repoRoot.appendingPathComponent("build/encrypted-xcframeworks")

if FileManager.default.fileExists(atPath: encryptedDir.path) {
    print("  [Encrypted Frameworks]")
    let contents = try FileManager.default.contentsOfDirectory(
        at: encryptedDir,
        includingPropertiesForKeys: nil
    )
    let encryptedFrameworks = contents.filter { $0.pathExtension == "xcframework" }

    test("Encrypted frameworks directory has files") {
        return !encryptedFrameworks.isEmpty
    }

    for fw in encryptedFrameworks {
        let name = fw.deletingPathExtension().lastPathComponent
        test("\(name) has AIPRD-ENC-V1 header") {
            let data = try Data(contentsOf: fw, options: .mappedIfSafe)
            return data.prefix(magicHeader.count) == magicHeader
        }
        test("\(name) decrypts successfully") {
            let data = try Data(contentsOf: fw)
            let decrypted = try decryptData(data, key: testKey)
            return decrypted.count > 0
        }
    }
    print("")
}

// --- Summary ---
print("═══════════════════════════════════════════════════════")
print("  Test Results: \(passed) passed, \(failed) failed")
print("═══════════════════════════════════════════════════════")

if failed > 0 {
    exit(1)
}
