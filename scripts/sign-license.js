#!/usr/bin/env node
/**
 * sign-license.js — Dev tool to sign a license key for the MCP server
 *
 * Produces an AIPRD-{base64(JSON)} key that the MCP server's
 * verifyLicenseSignature() accepts (sorted-JSON-keys Ed25519 signature).
 *
 * Reads an Ed25519 private key from ~/.aiprd/private-key.pem.
 *
 * Usage:
 *   node scripts/sign-license.js --email user@example.com --tier licensed
 *
 * Options:
 *   --email      Licensee email (required)
 *   --tier       License tier: licensed | trial (default: licensed)
 *   --days       Days until expiry (default: 365)
 *   --features   Comma-separated feature list (default: all licensed features)
 *   --key        Path to Ed25519 private key (default: ~/.aiprd/private-key.pem)
 *   --output     Print the AIPRD-... key to stdout (default); or --output file:path
 */

"use strict";

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const os = require("os");

const AIPRD_HOME = path.join(os.homedir(), ".aiprd");

const ALL_FEATURES = [
  "advanced_rag",
  "business_kpis",
  "codebase_analysis",
  "full_verification",
  "thinking_strategies",
  "unlimited_clarification",
  "unlimited_prd_types",
];

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const key = argv[i];
    if (key.startsWith("--") && i + 1 < argv.length) {
      args[key.slice(2)] = argv[++i];
    }
  }
  return args;
}

function readPrivateKey(keyPath) {
  if (!fs.existsSync(keyPath)) {
    throw new Error(
      `Private key not found at ${keyPath}\n` +
        "Generate one with: openssl genpkey -algorithm ed25519 -out ~/.aiprd/private-key.pem"
    );
  }

  const pem = fs.readFileSync(keyPath, "utf8").trim();

  if (pem.includes("-----BEGIN")) {
    return crypto.createPrivateKey(pem);
  }

  // Raw 32-byte seed encoded as base64
  const seed = Buffer.from(pem, "base64");
  if (seed.length !== 32) {
    throw new Error(
      `Expected 32-byte Ed25519 seed, got ${seed.length} bytes.`
    );
  }
  const pkcs8Prefix = Buffer.from(
    "302e020100300506032b657004220420",
    "hex"
  );
  const der = Buffer.concat([pkcs8Prefix, seed]);
  return crypto.createPrivateKey({ key: der, format: "der", type: "pkcs8" });
}

function main() {
  const args = parseArgs(process.argv);

  if (!args.email) {
    console.error("Error: --email is required");
    console.error(
      "Usage: node scripts/sign-license.js --email EMAIL [--tier licensed] [--days 365]"
    );
    process.exit(1);
  }

  const email = args.email;
  const tier = args.tier || "licensed";
  const days = parseInt(args.days || "365", 10);
  const features = args.features
    ? args.features.split(",").map((f) => f.trim())
    : ALL_FEATURES;
  const keyPath = args.key || path.join(AIPRD_HOME, "private-key.pem");

  if (!["licensed", "trial"].includes(tier)) {
    console.error('Error: --tier must be "licensed" or "trial"');
    process.exit(1);
  }

  const expiresAt = new Date(Date.now() + days * 86_400_000).toISOString();

  console.error(`Signing license for ${email} (${tier})...`);
  console.error(`  Expires: ${expiresAt} (${days} days)`);
  console.error(`  Features: ${features.join(", ")}`);

  const privateKey = readPrivateKey(keyPath);

  // Build the license data object (without signature)
  // The MCP server's verifyLicenseSignature does:
  //   const { signature, ...data } = license;
  //   const payload = JSON.stringify(data, Object.keys(data).sort());
  //   crypto.verify(null, Buffer.from(payload), publicKey, Buffer.from(signature, "base64"));
  const data = {
    email,
    enabled_features: features,
    expires_at: expiresAt,
    tier,
  };

  // Sign with sorted keys (matching MCP server verification)
  const sortedKeys = Object.keys(data).sort();
  const payload = JSON.stringify(data, sortedKeys);
  const signature = crypto.sign(null, Buffer.from(payload), privateKey);
  const signatureB64 = signature.toString("base64");

  console.error(`  Payload: ${payload}`);

  // Build the final license object with signature
  const license = { ...data, signature: signatureB64 };

  // Encode as AIPRD-{base64(JSON)} key
  const licenseJson = JSON.stringify(license);
  const aiprdKey = "AIPRD-" + Buffer.from(licenseJson).toString("base64");

  if (args.output && args.output.startsWith("file:")) {
    const outPath = args.output.slice(5);
    const dir = path.dirname(outPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(outPath, aiprdKey + "\n");
    console.error(`\nKey written to: ${outPath}`);
  } else {
    // Print key to stdout for piping
    process.stdout.write(aiprdKey + "\n");
    console.error("\nActivate with:");
    console.error(
      `  ~/.aiprd/run-mcp.sh --cli activate_license '{"key":"${aiprdKey}"}'`
    );
  }
}

main();
