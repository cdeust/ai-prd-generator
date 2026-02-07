#!/usr/bin/env swift
// generate-keypair.swift — Generate Ed25519 keypair for AIPRD license signing
// Usage: swift scripts/generate-keypair.swift

import CryptoKit
import Foundation

let aiprdDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".aiprd")

// Create directory if needed
try FileManager.default.createDirectory(at: aiprdDir, withIntermediateDirectories: true)

let privateKeyPath = aiprdDir.appendingPathComponent("private-key.pem")

// Check if key already exists
if FileManager.default.fileExists(atPath: privateKeyPath.path) {
    print("⚠️  Private key already exists at: \(privateKeyPath.path)")
    print("   Loading existing key...")

    let existingKeyData = try Data(contentsOf: privateKeyPath)
    guard let existingKeyRaw = Data(base64Encoded: String(data: existingKeyData, encoding: .utf8)!
        .trimmingCharacters(in: .whitespacesAndNewlines)) else {
        fatalError("Failed to decode existing private key")
    }
    let existingKey = try Curve25519.Signing.PrivateKey(rawRepresentation: existingKeyRaw)
    let publicKeyBase64 = existingKey.publicKey.rawRepresentation.base64EncodedString()

    print("")
    print("═══════════════════════════════════════════════════════")
    print("  EXISTING Ed25519 PUBLIC KEY (embed in SecureLicenseValidator)")
    print("═══════════════════════════════════════════════════════")
    print("")
    print("  \(publicKeyBase64)")
    print("")
    print("═══════════════════════════════════════════════════════")
    print("")
    print("Private key: \(privateKeyPath.path)")
} else {
    // Generate new keypair
    let privateKey = Curve25519.Signing.PrivateKey()
    let publicKey = privateKey.publicKey

    let privateKeyBase64 = privateKey.rawRepresentation.base64EncodedString()
    let publicKeyBase64 = publicKey.rawRepresentation.base64EncodedString()

    // Save private key
    try privateKeyBase64.write(to: privateKeyPath, atomically: true, encoding: .utf8)

    // Restrict permissions to owner-only
    try FileManager.default.setAttributes(
        [.posixPermissions: 0o600],
        ofItemAtPath: privateKeyPath.path
    )

    print("✅ Ed25519 keypair generated successfully")
    print("")
    print("═══════════════════════════════════════════════════════")
    print("  PUBLIC KEY (embed in SecureLicenseValidator.swift)")
    print("═══════════════════════════════════════════════════════")
    print("")
    print("  \(publicKeyBase64)")
    print("")
    print("═══════════════════════════════════════════════════════")
    print("")
    print("Private key saved to: \(privateKeyPath.path)")
    print("   Permissions: 600 (owner read/write only)")
    print("")
    print("⚠️  NEVER commit the private key to git!")
    print("   It stays on this machine only.")
}
