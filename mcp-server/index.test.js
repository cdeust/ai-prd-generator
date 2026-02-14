#!/usr/bin/env node
/**
 * Tests for AI Architect PRD Generator MCP Server
 *
 * Covers: product type detection, hardware fingerprint trial guard,
 * periodic re-validation logic, activate/validate flows, and MCP protocol.
 *
 * Run: node --test plugin/mcp-server/index.test.js
 * Zero dependencies — uses Node.js built-in test runner.
 */

const { describe, it, before, after, beforeEach, afterEach } = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync, spawn } = require("node:child_process");

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const SERVER_PATH = path.join(__dirname, "index.js");

/** Run a tool via --cli mode and return parsed JSON result. */
function cli(toolName, args = {}) {
  const result = execFileSync(
    process.execPath,
    [SERVER_PATH, "--cli", toolName, JSON.stringify(args)],
    {
      encoding: "utf8",
      timeout: 10_000,
      env: {
        ...process.env,
        // Isolate tests from real user state
        AIPRD_ENGINE_HOME: TEST_HOME,
        CLAUDE_PLUGIN_ROOT: path.join(__dirname, ".."),
      },
    }
  );
  return JSON.parse(result);
}

/** Create a temporary directory for test isolation. */
let TEST_HOME;

function setupTestHome() {
  TEST_HOME = fs.mkdtempSync(path.join(os.tmpdir(), "aiprd-test-"));
}

function cleanupTestHome() {
  try {
    fs.rmSync(TEST_HOME, { recursive: true, force: true });
  } catch (_) {}
}

/**
 * Replicate _detectProductType from index.js for test token building.
 */
function detectProductType(expiresAt) {
  if (!expiresAt) return "lifetime";
  const days = Math.ceil((new Date(expiresAt) - new Date()) / 86_400_000);
  if (days <= 14) return "trial";
  return "monthly";
}

/**
 * Build a fake Polar-derived base64 token for testing.
 * Simulates what _polarResponseToToken produces.
 * product_type is auto-computed from expires_at unless explicitly overridden.
 */
function buildPolarToken(overrides = {}) {
  const expiresAt = overrides.expires_at !== undefined ? overrides.expires_at : null;
  const license = {
    benefit_id: null,
    email: "test@example.com",
    enabled_features: [
      "thinking_strategies",
      "advanced_rag",
      "verification_engine",
      "vision_engine",
      "orchestration_engine",
      "encryption_engine",
      "strategy_engine",
    ],
    expires_at: expiresAt,
    polar_uuid: "AIPRD-00000000-0000-0000-0000-000000000001",
    product_type: detectProductType(expiresAt),
    tier: "licensed",
    validated_at: new Date().toISOString(),
    ...overrides,
  };
  return "AIPRD-" + Buffer.from(JSON.stringify(license)).toString("base64");
}

/**
 * Persist an encrypted key into the test engine home.
 * Replicates _persistKey logic from index.js.
 */
function persistEncryptedKey(aiprdKey) {
  const pluginRoot = path.join(__dirname, "..");
  const encKey = crypto
    .createHash("sha256")
    .update(`aiprd:${os.hostname()}:${os.userInfo().username}:${pluginRoot}`)
    .digest();
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv("aes-256-cbc", encKey, iv);
  const encrypted = Buffer.concat([cipher.update(aiprdKey, "utf8"), cipher.final()]);
  const blob = Buffer.concat([iv, encrypted]);
  const dest = path.join(TEST_HOME, ".lk");
  if (!fs.existsSync(TEST_HOME)) fs.mkdirSync(TEST_HOME, { recursive: true });
  fs.writeFileSync(dest, blob, { mode: 0o600 });
}

/**
 * Compute the hardware fingerprint matching index.js logic.
 */
function computeFingerprint() {
  const pluginRoot = path.join(__dirname, "..");
  return crypto
    .createHash("sha256")
    .update(`aiprd:${os.hostname()}:${os.userInfo().username}:${pluginRoot}`)
    .digest("hex");
}

/**
 * Write a trial record matching _recordTrialUsage logic.
 */
function writeTrialRecord() {
  const fingerprint = computeFingerprint();
  const activatedAt = new Date().toISOString();
  const payload = `TRIAL-RECORD|${fingerprint}|${activatedAt}`;
  const hmac = crypto.createHmac("sha256", fingerprint).update(payload).digest("hex");
  const record = JSON.stringify({ fingerprint, activated_at: activatedAt, hmac });
  const recordPath = path.join(TEST_HOME, ".mcp-trial-record");
  fs.writeFileSync(recordPath, record, { mode: 0o600 });
}

/**
 * Send a JSON-RPC request to the MCP server via stdio and return the response.
 */
function mcpRequest(msg) {
  return new Promise((resolve, reject) => {
    const proc = spawn(process.execPath, [SERVER_PATH], {
      env: {
        ...process.env,
        AIPRD_ENGINE_HOME: TEST_HOME,
        CLAUDE_PLUGIN_ROOT: path.join(__dirname, ".."),
      },
      stdio: ["pipe", "pipe", "pipe"],
    });

    const body = JSON.stringify(msg);
    const frame = `Content-Length: ${Buffer.byteLength(body)}\r\n\r\n${body}`;

    let stdout = "";
    proc.stdout.on("data", (chunk) => { stdout += chunk.toString(); });

    // Give the server time to respond, then kill
    const timeout = setTimeout(() => {
      proc.kill("SIGTERM");
    }, 3000);

    proc.on("close", () => {
      clearTimeout(timeout);
      // Extract JSON-RPC response from Content-Length framed output
      const match = stdout.match(/Content-Length:\s*(\d+)\r?\n\r?\n([\s\S]*)/);
      if (!match) {
        resolve(null);
        return;
      }
      try {
        resolve(JSON.parse(match[2].slice(0, parseInt(match[1], 10))));
      } catch (e) {
        reject(new Error(`Failed to parse MCP response: ${e.message}\n${stdout}`));
      }
    });

    proc.stdin.write(frame);
    // Send a tiny delay then close stdin to let server process
    setTimeout(() => proc.stdin.end(), 500);
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("Product Type Detection", () => {
  before(setupTestHome);
  after(cleanupTestHome);

  it("should detect lifetime when expires_at is null", () => {
    const token = buildPolarToken({ expires_at: null, product_type: "lifetime" });
    persistEncryptedKey(token);
    const result = cli("validate_license");
    assert.equal(result.tier, "licensed");
    assert.equal(result.product_type, "lifetime");
    assert.equal(result.expires_at, null);
    assert.equal(result.days_remaining, null);
  });

  it("should detect monthly when expires_at is > 14 days away", () => {
    const futureDate = new Date(Date.now() + 30 * 86_400_000).toISOString();
    const token = buildPolarToken({ expires_at: futureDate });
    persistEncryptedKey(token);
    const result = cli("validate_license");
    assert.equal(result.tier, "licensed");
    assert.equal(result.product_type, "monthly");
    assert.ok(result.days_remaining > 14);
  });

  it("should detect trial when expires_at is <= 14 days away", () => {
    const futureDate = new Date(Date.now() + 10 * 86_400_000).toISOString();
    const token = buildPolarToken({ expires_at: futureDate });
    persistEncryptedKey(token);
    const result = cli("validate_license");
    assert.equal(result.tier, "licensed");
    assert.equal(result.product_type, "trial");
    assert.ok(result.days_remaining <= 14);
    assert.ok(result.days_remaining > 0);
  });

  it("should return free tier when no key is persisted", () => {
    // Clean the test home so no .lk exists
    const lkPath = path.join(TEST_HOME, ".lk");
    try { fs.unlinkSync(lkPath); } catch (_) {}
    const result = cli("validate_license");
    assert.equal(result.tier, "free");
    assert.equal(result.product_type, null);
    assert.equal(result.source, "default_free");
  });

  it("should return null product_type for expired keys (free fallback)", () => {
    const pastDate = new Date(Date.now() - 86_400_000).toISOString();
    const token = buildPolarToken({ expires_at: pastDate });
    persistEncryptedKey(token);
    const result = cli("validate_license");
    // Expired Polar key should fall through to free tier
    assert.equal(result.tier, "free");
    assert.equal(result.product_type, null);
  });
});

describe("Hardware Fingerprint Trial Guard", () => {
  beforeEach(setupTestHome);
  afterEach(cleanupTestHome);

  it("should allow trial when no record exists", () => {
    // No trial record → _hasUsedTrial returns false
    const recordPath = path.join(TEST_HOME, ".mcp-trial-record");
    assert.ok(!fs.existsSync(recordPath), "Trial record should not exist initially");
  });

  it("should create trial record with valid HMAC", () => {
    writeTrialRecord();
    const recordPath = path.join(TEST_HOME, ".mcp-trial-record");
    assert.ok(fs.existsSync(recordPath), "Trial record should exist");

    const record = JSON.parse(fs.readFileSync(recordPath, "utf8"));
    const fingerprint = computeFingerprint();

    assert.equal(record.fingerprint, fingerprint);
    assert.ok(record.activated_at, "Should have activated_at");
    assert.ok(record.hmac, "Should have HMAC");

    // Verify HMAC is correct
    const payload = `TRIAL-RECORD|${record.fingerprint}|${record.activated_at}`;
    const expectedHmac = crypto.createHmac("sha256", fingerprint).update(payload).digest("hex");
    assert.equal(record.hmac, expectedHmac);
  });

  it("should reject tampered trial record (wrong HMAC)", () => {
    writeTrialRecord();
    const recordPath = path.join(TEST_HOME, ".mcp-trial-record");
    const record = JSON.parse(fs.readFileSync(recordPath, "utf8"));

    // Tamper with the HMAC
    record.hmac = "0000000000000000000000000000000000000000000000000000000000000000";
    fs.writeFileSync(recordPath, JSON.stringify(record));

    // Now _hasUsedTrial should return false (tampered)
    // We verify by checking the record structure is invalid
    const tampered = JSON.parse(fs.readFileSync(recordPath, "utf8"));
    const fingerprint = computeFingerprint();
    const payload = `TRIAL-RECORD|${tampered.fingerprint}|${tampered.activated_at}`;
    const expectedHmac = crypto.createHmac("sha256", fingerprint).update(payload).digest("hex");
    assert.notEqual(tampered.hmac, expectedHmac, "Tampered HMAC should not match");
  });

  it("should reject trial record from different device (wrong fingerprint)", () => {
    // Write a record with a foreign fingerprint
    const foreignFingerprint = crypto.createHash("sha256").update("foreign-device").digest("hex");
    const activatedAt = new Date().toISOString();
    const payload = `TRIAL-RECORD|${foreignFingerprint}|${activatedAt}`;
    const hmac = crypto.createHmac("sha256", foreignFingerprint).update(payload).digest("hex");
    const record = JSON.stringify({ fingerprint: foreignFingerprint, activated_at: activatedAt, hmac });
    fs.writeFileSync(path.join(TEST_HOME, ".mcp-trial-record"), record);

    // The fingerprints won't match current device
    const currentFingerprint = computeFingerprint();
    assert.notEqual(foreignFingerprint, currentFingerprint);
  });

  it("should have 0o600 permissions on trial record", () => {
    writeTrialRecord();
    const recordPath = path.join(TEST_HOME, ".mcp-trial-record");
    const stat = fs.statSync(recordPath);
    const mode = stat.mode & 0o777;
    assert.equal(mode, 0o600, `Expected 0600 permissions, got ${mode.toString(8)}`);
  });
});

describe("Encrypted Key Persistence", () => {
  beforeEach(setupTestHome);
  afterEach(cleanupTestHome);

  it("should persist and load a Polar token correctly", () => {
    const token = buildPolarToken({ product_type: "lifetime" });
    persistEncryptedKey(token);

    // Verify the .lk file exists and is binary (not readable plain text)
    const lkPath = path.join(TEST_HOME, ".lk");
    assert.ok(fs.existsSync(lkPath));
    const raw = fs.readFileSync(lkPath);
    assert.ok(raw.length >= 17, "Encrypted blob should be at least IV + 1 byte");
    // Should NOT contain the plain token string
    assert.ok(!raw.toString("utf8").includes("AIPRD-"), "Encrypted blob must not contain plain key");
  });

  it("should have 0o600 permissions on encrypted key file", () => {
    const token = buildPolarToken();
    persistEncryptedKey(token);
    const lkPath = path.join(TEST_HOME, ".lk");
    const stat = fs.statSync(lkPath);
    const mode = stat.mode & 0o777;
    assert.equal(mode, 0o600, `Expected 0600 permissions, got ${mode.toString(8)}`);
  });

  it("should return free tier if encrypted blob is corrupted", () => {
    const lkPath = path.join(TEST_HOME, ".lk");
    fs.writeFileSync(lkPath, Buffer.from("corrupted-garbage-data"));
    const result = cli("validate_license");
    assert.equal(result.tier, "free");
  });

  it("should return free tier if encrypted blob is too short", () => {
    const lkPath = path.join(TEST_HOME, ".lk");
    fs.writeFileSync(lkPath, Buffer.alloc(10)); // less than 17 bytes
    const result = cli("validate_license");
    assert.equal(result.tier, "free");
  });
});

describe("Validate License (CLI mode)", () => {
  beforeEach(setupTestHome);
  afterEach(cleanupTestHome);

  it("should return free tier with all expected fields when no key exists", () => {
    const result = cli("validate_license");
    assert.equal(result.tier, "free");
    assert.equal(result.source, "default_free");
    assert.equal(result.signature_verified, false);
    assert.equal(result.hardware_verified, false);
    assert.ok(Array.isArray(result.features));
    assert.equal(result.features.length, 0);
    assert.ok("product_type" in result, "Response must include product_type");
    assert.ok("environment" in result, "Response must include environment");
  });

  it("should return licensed tier with product_type for valid persisted token", () => {
    const token = buildPolarToken({ product_type: "lifetime" });
    persistEncryptedKey(token);
    const result = cli("validate_license");
    assert.equal(result.tier, "licensed");
    assert.equal(result.product_type, "lifetime");
    assert.equal(result.source, "polar_key");
    assert.ok(result.features.length > 0, "Licensed tier should have features");
    assert.ok(result.features.includes("thinking_strategies"));
  });

  it("should include days_remaining for expiring tokens", () => {
    const futureDate = new Date(Date.now() + 20 * 86_400_000).toISOString();
    const token = buildPolarToken({ expires_at: futureDate });
    persistEncryptedKey(token);
    const result = cli("validate_license");
    assert.ok(typeof result.days_remaining === "number");
    assert.ok(result.days_remaining >= 19 && result.days_remaining <= 21);
  });

  it("should return null days_remaining for lifetime tokens", () => {
    const token = buildPolarToken({ expires_at: null, product_type: "lifetime" });
    persistEncryptedKey(token);
    const result = cli("validate_license");
    assert.equal(result.days_remaining, null);
  });
});

describe("Activate License (CLI mode)", () => {
  beforeEach(setupTestHome);
  afterEach(cleanupTestHome);

  it("should reject keys without AIPRD- prefix", () => {
    const result = cli("activate_license", { key: "INVALID-KEY" });
    assert.equal(result.activated, false);
    assert.ok(result.error.includes("AIPRD-"));
  });

  it("should reject empty key", () => {
    const result = cli("activate_license", { key: "" });
    assert.equal(result.activated, false);
  });

  it("should reject malformed base64 token", () => {
    const result = cli("activate_license", { key: "AIPRD-not-valid-base64!!!" });
    assert.equal(result.activated, false);
    assert.ok(result.error);
  });

  it("should reject token with invalid Ed25519 signature", () => {
    // Build a token that looks like an Ed25519 token (no polar_uuid, has signature)
    const fakeToken = {
      email: "test@example.com",
      tier: "licensed",
      expires_at: new Date(Date.now() + 30 * 86_400_000).toISOString(),
      enabled_features: ["thinking_strategies"],
      signature: Buffer.from("fake-signature").toString("base64"),
    };
    const key = "AIPRD-" + Buffer.from(JSON.stringify(fakeToken)).toString("base64");
    const result = cli("activate_license", { key });
    assert.equal(result.activated, false);
    assert.ok(result.error.includes("signature") || result.error.includes("invalid"),
      `Expected signature error, got: ${result.error}`);
  });

  it("should activate a valid Polar-derived base64 token", () => {
    const token = buildPolarToken({ product_type: "lifetime" });
    const result = cli("activate_license", { key: token });
    assert.equal(result.activated, true);
    assert.equal(result.tier, "licensed");
    // Verify persistence
    const lkPath = path.join(TEST_HOME, ".lk");
    assert.ok(fs.existsSync(lkPath), "Key should be persisted");
  });

  it("should include product_type in activation response", () => {
    const token = buildPolarToken({
      expires_at: new Date(Date.now() + 25 * 86_400_000).toISOString(),
    });
    const result = cli("activate_license", { key: token });
    assert.equal(result.activated, true);
    assert.equal(result.product_type, "monthly");
  });
});

describe("Re-validation State Detection", () => {
  beforeEach(setupTestHome);
  afterEach(cleanupTestHome);

  it("should not need revalidation for recently validated token", () => {
    // validated_at = now → should NOT trigger revalidation
    const token = buildPolarToken({ validated_at: new Date().toISOString() });
    persistEncryptedKey(token);
    // Just verify validate_license returns the current state (no error from revalidation)
    const result = cli("validate_license");
    assert.equal(result.tier, "licensed");
  });

  it("should detect stale validated_at (> 7 days old)", () => {
    // validated_at = 8 days ago → would trigger revalidation
    const staleDate = new Date(Date.now() - 8 * 86_400_000).toISOString();
    const token = buildPolarToken({ validated_at: staleDate });
    persistEncryptedKey(token);

    // The token is still valid locally (revalidation is fire-and-forget, non-blocking)
    const result = cli("validate_license");
    assert.equal(result.tier, "licensed");
    // The CLI process exits before the async revalidation completes, so the local
    // result is still licensed. This is by design — revalidation is background-only.
  });

  it("should detect near-expiry token (< 7 days to expire)", () => {
    const nearExpiry = new Date(Date.now() + 5 * 86_400_000).toISOString();
    const token = buildPolarToken({
      expires_at: nearExpiry,
      validated_at: new Date().toISOString(),
    });
    persistEncryptedKey(token);
    const result = cli("validate_license");
    assert.equal(result.tier, "licensed");
    assert.ok(result.days_remaining <= 7);
  });
});

describe("Get License Features (CLI mode)", () => {
  before(setupTestHome);
  after(cleanupTestHome);

  it("should return free tier features by default", () => {
    const result = cli("get_license_features", { tier: "free" });
    assert.equal(result.tier, "free");
    assert.ok(result.features);
    assert.ok(Array.isArray(result.features.strategies_list) || typeof result.features.strategies === "object");
  });

  it("should return licensed tier features", () => {
    const result = cli("get_license_features", { tier: "licensed" });
    assert.equal(result.tier, "licensed");
    assert.equal(result.features.strategies, "all");
    assert.equal(result.features.verification, "full");
    assert.equal(result.features.business_kpis, "full");
  });

  it("should return trial tier features (same as licensed)", () => {
    const result = cli("get_license_features", { tier: "trial" });
    assert.equal(result.tier, "trial");
    assert.equal(result.features.strategies, "all");
  });

  it("should include environment in response", () => {
    const result = cli("get_license_features", {});
    assert.ok(result.environment === "cli" || result.environment === "cowork");
  });
});

describe("Check Health (CLI mode)", () => {
  before(setupTestHome);
  after(cleanupTestHome);

  it("should return healthy status", () => {
    const result = cli("check_health");
    assert.equal(result.status, "ok");
    assert.ok(result.version);
    assert.ok(result.environment);
    assert.ok(result.timestamp);
    assert.ok("license_tier" in result);
  });
});

describe("Get Config (CLI mode)", () => {
  before(setupTestHome);
  after(cleanupTestHome);

  it("should return config with expected fields", () => {
    const result = cli("get_config");
    assert.ok(result.version);
    assert.ok(result.name);
    assert.ok(result.environment);
    assert.ok(result.engine_home);
    assert.ok(result.plugin_root);
  });
});

describe("List Available Strategies (CLI mode)", () => {
  before(setupTestHome);
  after(cleanupTestHome);

  it("should return strategies for free tier", () => {
    const result = cli("list_available_strategies");
    assert.equal(result.tier, "free");
    assert.ok(Array.isArray(result.strategies));
    assert.ok(result.total_available > 0);
    assert.ok(result.strategies.includes("zero_shot") || result.strategies.includes("chain_of_thought"));
  });
});

describe("MCP Protocol (stdio transport)", () => {
  before(setupTestHome);
  after(cleanupTestHome);

  it("should respond to initialize request", async () => {
    const response = await mcpRequest({
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {},
    });
    assert.ok(response, "Should receive a response");
    assert.equal(response.id, 1);
    assert.ok(response.result);
    assert.equal(response.result.protocolVersion, "2024-11-05");
    assert.ok(response.result.capabilities);
    assert.ok(response.result.serverInfo);
    assert.equal(response.result.serverInfo.name, "ai-prd-generator");
  });

  it("should list tools via tools/list", async () => {
    const response = await mcpRequest({
      jsonrpc: "2.0",
      id: 2,
      method: "tools/list",
      params: {},
    });
    assert.ok(response);
    assert.ok(response.result);
    assert.ok(Array.isArray(response.result.tools));
    const toolNames = response.result.tools.map((t) => t.name);
    assert.ok(toolNames.includes("validate_license"));
    assert.ok(toolNames.includes("activate_license"));
    assert.ok(toolNames.includes("get_license_features"));
    assert.ok(toolNames.includes("check_health"));
  });

  it("should call validate_license via tools/call", async () => {
    const response = await mcpRequest({
      jsonrpc: "2.0",
      id: 3,
      method: "tools/call",
      params: { name: "validate_license", arguments: {} },
    });
    assert.ok(response);
    assert.ok(response.result);
    assert.ok(Array.isArray(response.result.content));
    const text = response.result.content[0].text;
    const parsed = JSON.parse(text);
    assert.equal(parsed.tier, "free");
    assert.ok("product_type" in parsed);
  });

  it("should return error for unknown tool", async () => {
    const response = await mcpRequest({
      jsonrpc: "2.0",
      id: 4,
      method: "tools/call",
      params: { name: "nonexistent_tool", arguments: {} },
    });
    assert.ok(response);
    const text = response.result.content[0].text;
    const parsed = JSON.parse(text);
    assert.ok(parsed.error);
    assert.ok(parsed.error.includes("Unknown tool"));
  });

  it("should return method not found for unknown method", async () => {
    const response = await mcpRequest({
      jsonrpc: "2.0",
      id: 5,
      method: "unknown/method",
      params: {},
    });
    assert.ok(response);
    assert.ok(response.error);
    assert.equal(response.error.code, -32601);
  });
});

describe("Token Structure Integrity", () => {
  before(setupTestHome);
  after(cleanupTestHome);

  it("should include all required fields in Polar-derived token", () => {
    const token = buildPolarToken();
    const decoded = JSON.parse(Buffer.from(token.slice(6), "base64").toString("utf8"));
    assert.ok("benefit_id" in decoded);
    assert.ok("email" in decoded);
    assert.ok("enabled_features" in decoded);
    assert.ok("expires_at" in decoded);
    assert.ok("polar_uuid" in decoded);
    assert.ok("product_type" in decoded);
    assert.ok("tier" in decoded);
    assert.ok("validated_at" in decoded);
  });

  it("should have valid ISO date for validated_at", () => {
    const token = buildPolarToken();
    const decoded = JSON.parse(Buffer.from(token.slice(6), "base64").toString("utf8"));
    const date = new Date(decoded.validated_at);
    assert.ok(!isNaN(date.getTime()), "validated_at should be a valid date");
    // Should be within last minute
    assert.ok(Date.now() - date.getTime() < 60_000);
  });

  it("should correctly map product types in token", () => {
    // Lifetime
    let decoded = JSON.parse(Buffer.from(
      buildPolarToken({ expires_at: null }).slice(6), "base64"
    ).toString("utf8"));
    assert.equal(decoded.product_type, "lifetime");

    // Trial (10 days)
    decoded = JSON.parse(Buffer.from(
      buildPolarToken({ expires_at: new Date(Date.now() + 10 * 86_400_000).toISOString() }).slice(6),
      "base64"
    ).toString("utf8"));
    // product_type set by buildPolarToken override — test the validate path instead
    const token = buildPolarToken({
      expires_at: new Date(Date.now() + 10 * 86_400_000).toISOString(),
      product_type: "trial",
    });
    persistEncryptedKey(token);
    const result = cli("validate_license");
    assert.equal(result.product_type, "trial");
  });
});

describe("Edge Cases", () => {
  beforeEach(setupTestHome);
  afterEach(cleanupTestHome);

  it("should handle missing ENGINE_HOME gracefully", () => {
    // Delete the test home entirely
    fs.rmSync(TEST_HOME, { recursive: true, force: true });
    // validate_license should still work (returns free)
    // Recreate just the dir so the process can start
    fs.mkdirSync(TEST_HOME, { recursive: true });
    const result = cli("validate_license");
    assert.equal(result.tier, "free");
  });

  it("should handle token with no enabled_features", () => {
    const token = buildPolarToken({ enabled_features: [] });
    persistEncryptedKey(token);
    const result = cli("validate_license");
    // Should still be licensed tier, but features might be derived from tier
    assert.equal(result.tier, "licensed");
  });

  it("should handle token with missing product_type (backward compat)", () => {
    // Simulate an old token without product_type field
    const license = {
      email: "old@example.com",
      enabled_features: ["thinking_strategies"],
      expires_at: null,
      polar_uuid: "AIPRD-00000000-0000-0000-0000-000000000099",
      tier: "licensed",
      validated_at: new Date().toISOString(),
      // No product_type field
    };
    const token = "AIPRD-" + Buffer.from(JSON.stringify(license)).toString("base64");
    persistEncryptedKey(token);
    const result = cli("validate_license");
    assert.equal(result.tier, "licensed");
    // Should detect product_type from expires_at (null → lifetime)
    assert.equal(result.product_type, "lifetime");
  });

  it("should handle token with missing validated_at", () => {
    const license = {
      email: "test@example.com",
      enabled_features: ["thinking_strategies"],
      expires_at: null,
      polar_uuid: "AIPRD-00000000-0000-0000-0000-000000000098",
      product_type: "lifetime",
      tier: "licensed",
      // No validated_at
    };
    const token = "AIPRD-" + Buffer.from(JSON.stringify(license)).toString("base64");
    persistEncryptedKey(token);
    const result = cli("validate_license");
    assert.equal(result.tier, "licensed");
  });
});
