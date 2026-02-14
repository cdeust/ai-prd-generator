#!/usr/bin/env node
/**
 * AI Architect PRD Generator — Dual-Mode MCP Server (Zero Dependencies)
 *
 * Uses built-in Ed25519 validation with AES-256 encrypted persistence.
 * Works identically in CLI and Cowork modes — no external binaries.
 *
 * Environment detection is automatic via CLAUDE_PLUGIN_ROOT.
 * No external dependencies required — Node.js only.
 *
 * Transport: stdio (JSON-RPC 2.0). All logging to stderr.
 *
 * PATCH v1.0.0 — Fixes:
 *   1. github_login device flow broken by overly broad 404 handler
 *   2. Accept header override for non-API GitHub endpoints
 */

const crypto = require("crypto");
const fs = require("fs");
const https = require("https");
const os = require("os");
const path = require("path");
const { execSync } = require("child_process");

// ---------------------------------------------------------------------------
// HTTP helpers — zero-dependency HTTPS with redirect following
// ---------------------------------------------------------------------------

let _githubToken = null; // In-memory token from device flow or env

function getGitHubToken() {
  if (_githubToken) return _githubToken;
  if (process.env.GITHUB_TOKEN) return process.env.GITHUB_TOKEN;
  if (process.env.GH_TOKEN) return process.env.GH_TOKEN;
  // CLI fallback only — skip in Cowork (gh doesn't exist, execSync hangs)
  if (ENVIRONMENT === "cli") {
    try {
      const t = execSync("gh auth token 2>/dev/null", { encoding: "utf8", timeout: 2000 }).trim();
      if (t) return t;
    } catch (_) { /* not available */ }
  }
  return null;
}

function httpsRequest(method, url, body = null, extraHeaders = {}) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const isGitHub = parsed.hostname.includes("github");
    // FIX #2: Only set GitHub API Accept header for api.github.com,
    // not for github.com/login/* (device flow needs application/json)
    const isGitHubAPI = parsed.hostname === "api.github.com";
    const headers = {
      "User-Agent": "ai-prd-generator/1.0.0",
      ...(isGitHubAPI ? { Accept: "application/vnd.github.v3+json" } : {}),
      ...extraHeaders,
    };
    if (isGitHub) {
      const token = getGitHubToken();
      if (token) headers.Authorization = `Bearer ${token}`;
    }
    if (body) {
      headers["Content-Type"] = "application/json";
      headers["Content-Length"] = Buffer.byteLength(body);
    }

    const opts = {
      hostname: parsed.hostname,
      port: parsed.port || 443,
      path: parsed.pathname + parsed.search,
      method,
      headers,
    };

    const req = https.request(opts, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return httpsRequest(method, res.headers.location, body, extraHeaders)
          .then(resolve).catch(reject);
      }
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ status: res.statusCode, data });
        } else if (
          // FIX #1: Only trigger REPO_NOT_FOUND_OR_PRIVATE for actual repo API calls,
          // NOT for device flow endpoints (github.com/login/device/code) or other non-API URLs.
          // Previous code: `res.statusCode === 404 && isGitHub && !getGitHubToken()`
          // This matched github.com/login/device/code returning 404, masking the real error.
          res.statusCode === 404 &&
          isGitHubAPI &&
          parsed.pathname.startsWith("/repos/") &&
          !getGitHubToken()
        ) {
          reject(new Error(
            "REPO_NOT_FOUND_OR_PRIVATE: Repository returned 404. " +
            "If this is a private repo, call the github_login tool first to authenticate, " +
            "then retry this request."
          ));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data.slice(0, 500)}`));
        }
      });
      res.on("error", reject);
    });
    req.setTimeout(5000, () => {
      req.destroy(new Error("NETWORK_TIMEOUT: Request timed out after 5s. If running in Cowork, the VM may not have direct network access to external APIs. Use WebFetch tool or ask the user to paste code instead."));
    });
    req.on("error", reject);
    if (body) req.write(body);
    req.end();
  });
}

function httpsGet(url, extraHeaders = {}) {
  return httpsRequest("GET", url, null, extraHeaders);
}

function httpsPost(url, body, extraHeaders = {}) {
  return httpsRequest("POST", url, JSON.stringify(body), extraHeaders);
}

function parseGitHubUrl(url) {
  const m = url.match(/github\.com\/([^/]+)\/([^/\s#?]+)/);
  if (!m) return null;
  return { owner: m[1], repo: m[2].replace(/\.git$/, "") };
}

// ---------------------------------------------------------------------------
// GitHub Device Flow — OAuth without a callback server
// ---------------------------------------------------------------------------

const GITHUB_DEVICE_FLOW = {
  // client_id resolved lazily (skillConfig loaded after this block)
  get clientId() {
    return ((skillConfig.integrations || {}).github || {}).client_id || "Ov23liKSxDIHS1bUhczd";
  },
  scope: "repo read:org",
  pending: null, // { device_code, user_code, verification_uri, expires_at, interval }
};

async function startDeviceFlow() {
  const { data } = await httpsPost(
    "https://github.com/login/device/code",
    { client_id: GITHUB_DEVICE_FLOW.clientId, scope: GITHUB_DEVICE_FLOW.scope },
    { Accept: "application/json" }
  );
  const result = JSON.parse(data);
  if (result.error) throw new Error(result.error_description || result.error);

  GITHUB_DEVICE_FLOW.pending = {
    device_code: result.device_code,
    user_code: result.user_code,
    verification_uri: result.verification_uri,
    expires_at: Date.now() + (result.expires_in || 900) * 1000,
    interval: (result.interval || 5) * 1000,
  };

  return {
    user_code: result.user_code,
    verification_uri: result.verification_uri,
    expires_in: result.expires_in,
  };
}

async function pollDeviceFlow() {
  const pending = GITHUB_DEVICE_FLOW.pending;
  if (!pending) throw new Error("No pending device flow. Call github_login first.");
  if (Date.now() > pending.expires_at) {
    GITHUB_DEVICE_FLOW.pending = null;
    throw new Error("Device flow expired. Call github_login again.");
  }

  const { data } = await httpsPost(
    "https://github.com/login/oauth/access_token",
    {
      client_id: GITHUB_DEVICE_FLOW.clientId,
      device_code: pending.device_code,
      grant_type: "urn:ietf:params:oauth:grant-type:device_code",
    },
    { Accept: "application/json" }
  );
  const result = JSON.parse(data);

  if (result.access_token) {
    _githubToken = result.access_token;
    GITHUB_DEVICE_FLOW.pending = null;
    return { authenticated: true, scope: result.scope, token_type: result.token_type };
  }

  if (result.error === "authorization_pending") {
    return { authenticated: false, status: "waiting", message: "User hasn't authorized yet. Call github_poll again." };
  }
  if (result.error === "slow_down") {
    pending.interval += 5000;
    return { authenticated: false, status: "slow_down", message: "Polling too fast. Waiting longer." };
  }

  throw new Error(result.error_description || result.error || "Unknown error");
}

// ---------------------------------------------------------------------------
// Ed25519 Public Key — for license signature verification
// The private key is NEVER shipped. Only the author can sign licenses.
// ---------------------------------------------------------------------------

const LICENSE_PUBLIC_KEY = `-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAoqKxCXUCWxvRwExXDLPN9QBfncHmrQLVdYSIK2s+DZg=
-----END PUBLIC KEY-----`;

// ---------------------------------------------------------------------------
// Paths & Config
// ---------------------------------------------------------------------------

const PLUGIN_ROOT =
  process.env.CLAUDE_PLUGIN_ROOT || path.resolve(__dirname, "..");
const SKILL_CONFIG_PATH =
  process.env.AIPRD_SKILL_CONFIG ||
  path.join(PLUGIN_ROOT, "skill-config.json");
const ENGINE_HOME =
  process.env.AIPRD_ENGINE_HOME ||
  path.join(os.homedir(), ".aiprd");

let skillConfig = {};
try {
  skillConfig = JSON.parse(fs.readFileSync(SKILL_CONFIG_PATH, "utf8"));
} catch (_) {
  process.stderr.write(
    `[ai-prd-generator] Warning: Could not load skill-config.json from ${SKILL_CONFIG_PATH}\n`
  );
}

// ---------------------------------------------------------------------------
// Environment Detection
// ---------------------------------------------------------------------------

function detectEnvironment() {
  // Cowork sets CLAUDE_PLUGIN_ROOT and runs in /sessions/
  if (
    process.env.CLAUDE_PLUGIN_ROOT ||
    (process.cwd() || "").startsWith("/sessions/")
  ) {
    return "cowork";
  }
  return "cli";
}

const ENVIRONMENT = detectEnvironment();

// ---------------------------------------------------------------------------
// License Validation — Encrypted persistence, no readable files
// ---------------------------------------------------------------------------

// In-memory license state — populated from encrypted store on startup,
// or set by activate_license. No plain-text license data ever touches disk.
let _cachedLicense = null;

// Derive a per-machine AES-256 key from stable system identifiers.
// This ensures the encrypted blob is tied to this machine and not portable.
const _encKey = crypto
  .createHash("sha256")
  .update(`aiprd:${os.hostname()}:${os.userInfo().username}:${PLUGIN_ROOT}`)
  .digest();

function _storageLocation() {
  return path.join(ENGINE_HOME, ".lk");
}

function _persistKey(aiprdKey) {
  try {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv("aes-256-cbc", _encKey, iv);
    const encrypted = Buffer.concat([cipher.update(aiprdKey, "utf8"), cipher.final()]);
    const blob = Buffer.concat([iv, encrypted]);
    const dest = _storageLocation();
    const dir = path.dirname(dest);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(dest, blob, { mode: 0o600 });
  } catch (e) {
    process.stderr.write(`[ai-prd-generator] Could not persist activation: ${e.message}\n`);
  }
}

function _loadPersistedKey() {
  try {
    const blob = fs.readFileSync(_storageLocation());
    if (blob.length < 17) return null;
    const iv = blob.subarray(0, 16);
    const encrypted = blob.subarray(16);
    const decipher = crypto.createDecipheriv("aes-256-cbc", _encKey, iv);
    return Buffer.concat([decipher.update(encrypted), decipher.final()]).toString("utf8");
  } catch (_) {
    return null;
  }
}

// Polar.sh organization IDs for license key validation
const POLAR_ORG_ID = "3c29257d-7ddb-4ef1-98d4-3d63c491d653";
const POLAR_SANDBOX_ORG_ID = "33bddceb-c04b-40f7-a881-54402f1ddd4f";

// ---------------------------------------------------------------------------
// Periodic Polar Re-validation — detects subscription cancellations & renewals
// ---------------------------------------------------------------------------

const POLAR_REVALIDATION_INTERVAL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days
let _renewalInProgress = false;

function _needsRevalidation(licenseResult) {
  if (!licenseResult || licenseResult.source !== "polar_key") return false;
  // Parse the stored token to check validated_at
  const storedKey = _loadPersistedKey();
  if (!storedKey) return false;
  try {
    const decoded = Buffer.from(storedKey.slice(6), "base64").toString("utf8");
    const license = JSON.parse(decoded);
    if (!license.validated_at) return true;
    const validatedAt = new Date(license.validated_at).getTime();
    const age = Date.now() - validatedAt;
    if (age > POLAR_REVALIDATION_INTERVAL_MS) return true;
    // Also revalidate if expires_at is within 7 days (catch renewals early)
    if (license.expires_at) {
      const daysUntilExpiry = (new Date(license.expires_at) - new Date()) / 86_400_000;
      if (daysUntilExpiry <= 7) return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}

async function _revalidateWithPolar(storedToken) {
  let license;
  try {
    const decoded = Buffer.from(storedToken.slice(6), "base64").toString("utf8");
    license = JSON.parse(decoded);
  } catch (_) {
    return;
  }
  if (!license.polar_uuid) return;

  let polarResult;
  try {
    polarResult = await _validateWithPolar(license.polar_uuid);
  } catch (_) {
    // Network error — keep current token, retry next check
    return;
  }

  if (polarResult.status === "granted") {
    // Build fresh token with updated expires_at and validated_at
    const freshToken = _polarResponseToToken(polarResult, license.polar_uuid);
    const freshResult = _activateFromKey(freshToken);
    if (freshResult) {
      _cachedLicense = freshResult;
      _persistKey(freshToken);
      process.stderr.write("[ai-prd-generator] Polar re-validation: license refreshed\n");
    }
  } else if (polarResult.status === "revoked" || polarResult.status === "disabled") {
    // Key revoked or disabled — drop to free tier
    try { fs.unlinkSync(_storageLocation()); } catch (_) {}
    _cachedLicense = null;
    process.stderr.write(`[ai-prd-generator] Polar re-validation: key ${polarResult.status}, reverting to free tier\n`);
  }
}

function _maybeScheduleRevalidation(licenseResult, storedToken) {
  if (_renewalInProgress) return;
  if (!_needsRevalidation(licenseResult)) return;
  _renewalInProgress = true;
  _revalidateWithPolar(storedToken)
    .catch(() => {})
    .finally(() => { _renewalInProgress = false; });
}

// ---------------------------------------------------------------------------
// Hardware Fingerprint Trial Guard — prevents unlimited trial abuse
// ---------------------------------------------------------------------------

function _hardwareFingerprint() {
  return crypto.createHash("sha256")
    .update(`aiprd:${os.hostname()}:${os.userInfo().username}:${PLUGIN_ROOT}`)
    .digest("hex");
}

function _trialRecordPath() {
  return path.join(ENGINE_HOME, ".mcp-trial-record");
}

function _hasUsedTrial() {
  try {
    const data = fs.readFileSync(_trialRecordPath(), "utf8");
    const record = JSON.parse(data);
    const fingerprint = _hardwareFingerprint();
    // Verify HMAC
    const payload = `TRIAL-RECORD|${record.fingerprint}|${record.activated_at}`;
    const expectedHmac = crypto.createHmac("sha256", fingerprint).update(payload).digest("hex");
    if (record.hmac !== expectedHmac) return false;
    // Verify fingerprint matches current device
    if (record.fingerprint !== fingerprint) return false;
    return true;
  } catch (_) {
    return false;
  }
}

function _recordTrialUsage() {
  try {
    const fingerprint = _hardwareFingerprint();
    const activatedAt = new Date().toISOString();
    const payload = `TRIAL-RECORD|${fingerprint}|${activatedAt}`;
    const hmac = crypto.createHmac("sha256", fingerprint).update(payload).digest("hex");
    const record = JSON.stringify({ fingerprint, activated_at: activatedAt, hmac });
    const dir = path.dirname(_trialRecordPath());
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(_trialRecordPath(), record, { mode: 0o600 });
  } catch (e) {
    process.stderr.write(`[ai-prd-generator] Could not record trial usage: ${e.message}\n`);
  }
}

// ---------------------------------------------------------------------------
// Product Type Detection — trial vs monthly vs lifetime
// ---------------------------------------------------------------------------

function _detectProductType(expiresAt) {
  if (!expiresAt) return "lifetime";
  const days = Math.ceil((new Date(expiresAt) - new Date()) / 86_400_000);
  if (days <= 14) return "trial";
  return "monthly";
}

// Detect UUID-format Polar.sh keys: AIPRD-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
function _isPolarUuidKey(aiprdKey) {
  if (!aiprdKey || !aiprdKey.startsWith("AIPRD-")) return false;
  const remainder = aiprdKey.slice(6);
  return /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/i.test(remainder);
}

// Validate a UUID key against Polar.sh API
// Tries: production API + prod org → production API + sandbox org → sandbox API + sandbox org
async function _validateWithPolar(aiprdKey) {
  const endpoint = "/v1/customer-portal/license-keys/validate";
  const attempts = [
    { host: "api.polar.sh", orgId: POLAR_ORG_ID },
    { host: "api.polar.sh", orgId: POLAR_SANDBOX_ORG_ID },
    { host: "sandbox-api.polar.sh", orgId: POLAR_SANDBOX_ORG_ID },
  ];

  let lastError = null;
  for (const { host, orgId } of attempts) {
    try {
      const { data } = await httpsPost(
        `https://${host}${endpoint}`,
        { key: aiprdKey, organization_id: orgId }
      );
      const result = JSON.parse(data);
      if (result.status === "granted") return result;
    } catch (err) {
      lastError = err;
    }
  }

  throw lastError || new Error("All Polar.sh validation attempts failed");
}

// Convert a validated Polar response into a persistable AIPRD-{base64(JSON)} token.
// This ensures a single key format throughout the system (MCP server, Swift engine, etc.).
function _polarResponseToToken(polarResult, originalUuid) {
  const productType = _detectProductType(polarResult.expires_at);
  const license = {
    benefit_id: polarResult.benefit_id || null,
    email: (polarResult.customer || {}).email || "polar-customer",
    enabled_features: getFeaturesListForTier("licensed"),
    expires_at: polarResult.expires_at || null,
    polar_uuid: originalUuid,
    product_type: productType,
    tier: "licensed",
    validated_at: new Date().toISOString(),
  };
  return "AIPRD-" + Buffer.from(JSON.stringify(license)).toString("base64");
}

function _activateFromKey(aiprdKey) {
  if (!aiprdKey || !aiprdKey.startsWith("AIPRD-")) return null;

  // Self-contained base64 token (Ed25519-signed OR Polar-derived)
  let license;
  try {
    const decoded = Buffer.from(aiprdKey.slice(6), "base64").toString("utf8");
    license = JSON.parse(decoded);
  } catch (_) {
    return null;
  }

  // Polar-derived tokens: no Ed25519 signature, but have polar_uuid as proof.
  // Trusted because the token is stored in an AES-256 encrypted, machine-locked blob.
  if (license.polar_uuid) {
    const expiresAt = license.expires_at ? new Date(license.expires_at) : null;
    if (expiresAt && expiresAt <= new Date()) return null;
    return {
      tier: license.tier || "licensed",
      features: license.enabled_features || getFeaturesListForTier(license.tier || "licensed"),
      product_type: license.product_type || _detectProductType(license.expires_at),
      signature_verified: false,
      hardware_verified: false,
      expires_at: license.expires_at || null,
      days_remaining: expiresAt
        ? Math.ceil((expiresAt - new Date()) / 86_400_000)
        : null,
      source: "polar_key",
      environment: ENVIRONMENT,
      errors: [],
    };
  }

  // Ed25519-signed tokens: verify cryptographic signature
  if (!verifyLicenseSignature(license)) return null;
  const expiresAt = new Date(license.expires_at || 0);
  if (expiresAt <= new Date()) return null;
  return {
    tier: license.tier,
    features: license.enabled_features || getFeaturesListForTier(license.tier),
    signature_verified: true,
    hardware_verified: false,
    expires_at: license.expires_at,
    days_remaining: Math.ceil((expiresAt - new Date()) / 86_400_000),
    source: "activated_key",
    environment: ENVIRONMENT,
    errors: [],
  };
}

function validateLicense() {
  // 1. Return cached result if already resolved this session
  if (_cachedLicense) {
    // Schedule background re-validation if needed (fire-and-forget)
    const storedKey = _loadPersistedKey();
    if (storedKey) _maybeScheduleRevalidation(_cachedLicense, storedKey);
    return _cachedLicense;
  }

  // 2. Try loading from encrypted store (persisted by a previous activate_license)
  const storedKey = _loadPersistedKey();
  if (storedKey) {
    const result = _activateFromKey(storedKey);
    if (result) {
      _cachedLicense = result;
      // Schedule background re-validation if needed (fire-and-forget)
      _maybeScheduleRevalidation(result, storedKey);
      return result;
    }
  }

  // 3. No activation — default to free tier
  return freeTierResult();
}

function freeTierResult() {
  return {
    tier: "free",
    features: getFeaturesListForTier("free"),
    signature_verified: false,
    hardware_verified: false,
    expires_at: null,
    days_remaining: null,
    source: "default_free",
    environment: ENVIRONMENT,
    errors: [],
  };
}

function verifyLicenseSignature(license) {
  try {
    const { signature, ...data } = license;
    if (!signature) return false;
    const payload = JSON.stringify(data, Object.keys(data).sort());
    const publicKey = crypto.createPublicKey(LICENSE_PUBLIC_KEY);
    return crypto.verify(null, Buffer.from(payload), publicKey, Buffer.from(signature, "base64"));
  } catch (_) {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Feature resolution from skill-config.json
// ---------------------------------------------------------------------------

const ALL_LICENSED_FEATURES = [
  "thinking_strategies",
  "advanced_rag",
  "verification_engine",
  "vision_engine",
  "orchestration_engine",
  "encryption_engine",
  "strategy_engine",
];

function getFeaturesListForTier(tier) {
  if (tier === "licensed" || tier === "trial") {
    return ALL_LICENSED_FEATURES;
  }
  return [];
}

function getFeaturesForTier(tier) {
  const licenseConfig = skillConfig.license || {};

  if (tier === "licensed" || tier === "trial") {
    const tierKey = tier === "licensed" ? "licensed_tier" : "trial_tier";
    const tierConfig = licenseConfig[tierKey] || {};
    return {
      strategies: "all",
      strategies_list: (skillConfig.thinking || {}).available_strategies || [],
      prd_contexts: "all",
      prd_contexts_list: ((skillConfig.prd_contexts || {}).available) || [],
      max_clarification_rounds: "unlimited",
      max_clarification_questions: "context_aware",
      verification: "full",
      rag_max_hops: "context_aware",
      sections_limit: "context_aware",
      business_kpis: "full",
      ...tierConfig,
    };
  }

  // Free tier
  const freeTier = licenseConfig.free_tier || {};
  return {
    strategies: freeTier.strategies || ["zero_shot", "chain_of_thought"],
    strategies_list: freeTier.strategies || ["zero_shot", "chain_of_thought"],
    prd_contexts: freeTier.prd_contexts || ["feature", "bug"],
    prd_contexts_list: freeTier.prd_contexts || ["feature", "bug"],
    max_clarification_rounds: freeTier.max_clarification_rounds || 3,
    max_clarification_questions: freeTier.max_clarification_questions || 5,
    verification: freeTier.verification || "basic",
    rag_max_hops: freeTier.rag_max_hops || 1,
    sections_limit: freeTier.sections_limit || 6,
    business_kpis: freeTier.business_kpis || "summary_only",
  };
}

// ---------------------------------------------------------------------------
// MCP Tool definitions
// ---------------------------------------------------------------------------

const TOOLS = {
  validate_license: {
    description:
      "Validate the current license tier. Returns tier, features, product type, and validation details. Uses built-in Ed25519 verification.",
    inputSchema: { type: "object", properties: {}, required: [] },
    handler(_args) {
      const result = validateLicense();
      return {
        ...result,
        product_type: result.product_type || null,
      };
    },
  },

  activate_license: {
    description:
      "Activate a license key. Accepts Polar.sh UUID keys (AIPRD-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX) and self-contained signed tokens (AIPRD-{base64}). UUID keys are validated via Polar.sh API then converted to a base64 token. Signed tokens are verified locally with Ed25519. Both formats are persisted as encrypted blobs.",
    inputSchema: {
      type: "object",
      properties: {
        key: {
          type: "string",
          description:
            "The license key received after purchase (starts with AIPRD-)",
        },
      },
      required: ["key"],
    },
    async handler(args) {
      const key = (args.key || "").trim();
      if (!key.startsWith("AIPRD-")) {
        return {
          activated: false,
          error: "Invalid key format. License keys start with AIPRD-",
        };
      }

      // Path 1: Polar.sh UUID key — validate via API, then convert to base64 token
      if (_isPolarUuidKey(key)) {
        let polarResult;
        try {
          polarResult = await _validateWithPolar(key);
        } catch (err) {
          return {
            activated: false,
            error: `Could not reach Polar.sh to validate key: ${err.message}`,
          };
        }

        if (polarResult.status !== "granted") {
          return {
            activated: false,
            error: `License key validation failed: ${polarResult.status || "unknown"}. Check that the key is correct and active.`,
          };
        }

        // Polar confirmed — convert to base64 token for unified format
        const derivedToken = _polarResponseToToken(polarResult, key);
        const result = _activateFromKey(derivedToken);
        if (!result) {
          return { activated: false, error: "Internal error creating activation record." };
        }

        // Trial guard: prevent multiple trial activations on the same device
        if (result.product_type === "trial") {
          if (_hasUsedTrial()) {
            return {
              activated: false,
              error: "Trial already used on this device. Purchase a monthly or lifetime license to continue.",
            };
          }
          _recordTrialUsage();
        }

        _cachedLicense = result;
        _persistKey(derivedToken);

        // Product-type-specific success messages
        const messages = {
          trial: "14-day trial activated! Full access to all features.",
          monthly: "Monthly subscription activated — renews automatically.",
          lifetime: "Lifetime license activated — never expires.",
        };

        return {
          activated: true,
          tier: result.tier,
          product_type: result.product_type,
          features: result.features,
          expires_at: result.expires_at,
          days_remaining: result.days_remaining,
          message: messages[result.product_type] || "License activated! You now have full access to all licensed features.",
        };
      }

      // Path 2: Base64 token — Ed25519-signed or Polar-derived
      // _activateFromKey handles both: checks polar_uuid for Polar tokens,
      // verifies Ed25519 signature for author-signed tokens.
      const result = _activateFromKey(key);
      if (!result) {
        // Provide a specific error by attempting decode
        try {
          const decoded = Buffer.from(key.slice(6), "base64").toString("utf8");
          JSON.parse(decoded);
          // Decoded OK but validation failed
          return {
            activated: false,
            error: "License signature verification failed. This key is invalid or corrupted.",
          };
        } catch (_) {
          return {
            activated: false,
            error: "Could not decode license key. Ensure you copied the full key.",
          };
        }
      }

      _cachedLicense = result;
      _persistKey(key);

      return {
        activated: true,
        tier: result.tier,
        product_type: result.product_type || null,
        features: result.features,
        expires_at: result.expires_at,
        days_remaining: result.days_remaining,
        message: `License activated! You now have full access to all ${result.tier} features.`,
      };
    },
  },

  get_license_features: {
    description:
      "Get the full feature set available for a given license tier.",
    inputSchema: {
      type: "object",
      properties: {
        tier: {
          type: "string",
          enum: ["free", "trial", "licensed"],
          description: "The license tier to query features for",
        },
      },
      required: [],
    },
    handler(args) {
      const tier = args.tier || validateLicense().tier;
      return {
        tier,
        features: getFeaturesForTier(tier),
        environment: ENVIRONMENT,
      };
    },
  },

  get_config: {
    description: "Get the full plugin configuration.",
    inputSchema: { type: "object", properties: {}, required: [] },
    handler(_args) {
      return {
        version: skillConfig.version || "unknown",
        name: skillConfig.name || "AI Architect PRD Generator",
        environment: ENVIRONMENT,
        engine_home: ENGINE_HOME,
        plugin_root: PLUGIN_ROOT,
        prd_contexts: (skillConfig.prd_contexts || {}).available || [],
        supported_providers: (skillConfig.providers || {}).supported || [],
      };
    },
  },

  read_skill_config: {
    description:
      "Read a specific section of the skill configuration.",
    inputSchema: {
      type: "object",
      properties: {
        section: {
          type: "string",
          description:
            "Config section to read (e.g. 'license', 'prd_contexts', 'thinking', 'verification')",
        },
      },
      required: [],
    },
    handler(args) {
      if (args.section && skillConfig[args.section] !== undefined) {
        return { section: args.section, data: skillConfig[args.section] };
      }
      return {
        available_sections: Object.keys(skillConfig),
        hint: "Pass a section name to read its contents",
      };
    },
  },

  check_health: {
    description:
      "Check the health of the MCP server and its dependencies.",
    inputSchema: { type: "object", properties: {}, required: [] },
    handler(_args) {
      const license = validateLicense();
      const result = {
        status: "ok",
        version: skillConfig.version || "unknown",
        environment: ENVIRONMENT,
        skill_config_loaded: Object.keys(skillConfig).length > 0,
        license_tier: license.tier,
        license_activated: license.source === "activated_key",
        engine_home: ENGINE_HOME,
        plugin_root: PLUGIN_ROOT,
        timestamp: new Date().toISOString(),
      };
      if (ENVIRONMENT === "cowork") {
        result.cowork_info = {
          vm: "Ubuntu 22.04 ARM64 (isolated VM on user's local machine)",
          network: "Restricted allowlist — only api.anthropic.com, pypi.org, registry.npmjs.org. GitHub is BLOCKED.",
          github_access: false,
          docker_available: false,
          codebase_method: "User must share local directory. Use Glob/Grep/Read for analysis.",
          pre_installed: "Node.js 22, Python 3.10, git, ripgrep, jq, sqlite3",
          not_available: "gh CLI, docker, brew, psql, network access to GitHub",
        };
      }
      return result;
    },
  },

  get_prd_context_info: {
    description:
      "Get configuration details for a specific PRD context type.",
    inputSchema: {
      type: "object",
      properties: {
        context_type: {
          type: "string",
          enum: [
            "proposal", "feature", "bug", "incident",
            "poc", "mvp", "release", "cicd",
          ],
          description: "The PRD context type to query",
        },
      },
      required: [],
    },
    handler(args) {
      const contexts = skillConfig.prd_contexts || {};
      if (args.context_type && contexts.configurations) {
        const cfg = contexts.configurations[args.context_type];
        if (cfg) {
          const license = validateLicense();
          const freeContexts =
            (skillConfig.license || {}).free_tier?.prd_contexts || ["feature", "bug"];
          return {
            context_type: args.context_type,
            configuration: cfg,
            requires_license: !freeContexts.includes(args.context_type),
            current_tier: license.tier,
          };
        }
        return {
          error: `unknown context type '${args.context_type}'`,
          available: contexts.available || [],
        };
      }
      return {
        available_contexts: contexts.available || [],
        configurations: contexts.configurations || {},
      };
    },
  },

  list_available_strategies: {
    description:
      "List thinking strategies available for the current license tier.",
    inputSchema: { type: "object", properties: {}, required: [] },
    handler(_args) {
      const license = validateLicense();
      const thinking = skillConfig.thinking || {};
      const all = thinking.available_strategies || [];
      const prioritization = thinking.strategy_prioritization || {};

      if (license.tier === "free") {
        const freeStrategies =
          (skillConfig.license || {}).free_tier?.strategies ||
          (skillConfig.strategy_engine || {}).license_tiers?.free || [
            "zero_shot",
            "chain_of_thought",
          ];
        return {
          tier: license.tier,
          strategies: freeStrategies,
          total_available: freeStrategies.length,
          total_strategies: all.length,
          locked: all.filter((s) => !freeStrategies.includes(s)),
          prioritization,
        };
      }

      return {
        tier: license.tier,
        strategies: all,
        total_available: all.length,
        total_strategies: all.length,
        locked: [],
        prioritization,
      };
    },
  },

  // -------------------------------------------------------------------------
  // GitHub tools — CLI mode ONLY (require outbound HTTPS to github.com)
  // Cowork VMs block github.com via egress proxy allowlist (403 Forbidden).
  // These tools are hidden from tools/list in Cowork and return clear errors.
  // -------------------------------------------------------------------------

  github_login: {
    cli_only: true,
    description:
      "Start GitHub authentication via device flow. Returns a user code and URL — the user opens the URL, enters the code, and authorizes. Then call github_poll to complete. CLI mode only — Cowork VMs block GitHub network access.",
    inputSchema: { type: "object", properties: {}, required: [] },
    async handler(_args) {
      // Check if already authenticated
      const token = getGitHubToken();
      if (token) {
        try {
          const { data } = await httpsGet("https://api.github.com/user");
          const user = JSON.parse(data);
          return {
            authenticated: true,
            user: user.login,
            message: `Already authenticated as ${user.login}`,
          };
        } catch (_) {
          // Token invalid, proceed with new login
          _githubToken = null;
        }
      }

      const result = await startDeviceFlow();
      return {
        authenticated: false,
        action_required: true,
        user_code: result.user_code,
        verification_uri: result.verification_uri,
        message: `Open ${result.verification_uri} and enter code: ${result.user_code}`,
        expires_in_seconds: result.expires_in,
        next_step: "Call github_poll after the user has authorized",
      };
    },
  },

  github_poll: {
    cli_only: true,
    description:
      "Poll for GitHub device flow completion after the user has authorized. Call this after github_login once the user has entered their code. CLI mode only.",
    inputSchema: { type: "object", properties: {}, required: [] },
    async handler(_args) {
      const result = await pollDeviceFlow();
      if (result.authenticated) {
        // Fetch user info to confirm
        try {
          const { data } = await httpsGet("https://api.github.com/user");
          const user = JSON.parse(data);
          return {
            authenticated: true,
            user: user.login,
            message: `Authenticated as ${user.login}. GitHub tools now have access to your repositories.`,
          };
        } catch (_) {
          return result;
        }
      }
      return result;
    },
  },

  // -------------------------------------------------------------------------
  // GitHub API tools — alternative to gh CLI when it's not installed
  // CLI mode ONLY — Cowork VMs block github.com (403 Forbidden)
  // -------------------------------------------------------------------------

  fetch_github_tree: {
    cli_only: true,
    description:
      "Fetch the file tree of a GitHub repository. Makes direct HTTPS calls to GitHub API. CLI mode only — Cowork VMs block GitHub network access. For private repos, call github_login first.",
    inputSchema: {
      type: "object",
      properties: {
        url: {
          type: "string",
          description:
            "Full GitHub URL (e.g., 'https://github.com/owner/repo'). Extracts owner/repo automatically.",
        },
        owner: {
          type: "string",
          description: "Repository owner (alternative to url)",
        },
        repo: {
          type: "string",
          description: "Repository name (alternative to url)",
        },
        branch: {
          type: "string",
          description: "Branch name (default: 'main')",
        },
        path_filter: {
          type: "string",
          description:
            "Only return files under this directory (e.g., 'src/models')",
        },
      },
      required: [],
    },
    async handler(args) {
      let owner = args.owner;
      let repo = args.repo;

      if (args.url) {
        const parsed = parseGitHubUrl(args.url);
        if (!parsed) return { error: `Could not parse GitHub URL: ${args.url}` };
        owner = parsed.owner;
        repo = parsed.repo;
      }

      if (!owner || !repo) {
        return { error: "Provide either a GitHub URL or owner + repo" };
      }

      const branch = args.branch || "main";
      const apiUrl = `https://api.github.com/repos/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}/git/trees/${encodeURIComponent(branch)}?recursive=1`;

      let data;
      try {
        ({ data } = await httpsGet(apiUrl));
      } catch (e) {
        if (e.message.includes("REPO_NOT_FOUND_OR_PRIVATE")) {
          return {
            error: "auth_required",
            message: `Repository ${owner}/${repo} is private or not found. Call the github_login tool first to authenticate with GitHub, then retry.`,
            action: "github_login",
          };
        }
        if (e.message.includes("NETWORK_TIMEOUT") || e.message.includes("timed out")) {
          return {
            error: "network_unavailable",
            message: `Cannot reach GitHub API from this environment. This is expected in Cowork VMs. Use WebFetch tool with the GitHub URL to fetch repo info through Anthropic's infrastructure, or ask the user to paste relevant code.`,
            fallback: "webfetch_or_user_input",
          };
        }
        return { error: "request_failed", message: e.message };
      }

      const tree = JSON.parse(data);

      let files = (tree.tree || [])
        .filter((f) => f.type === "blob")
        .map((f) => ({ path: f.path, size: f.size }));

      if (args.path_filter) {
        files = files.filter((f) => f.path.startsWith(args.path_filter));
      }

      // Group by top-level directory
      const structure = {};
      for (const f of files) {
        const parts = f.path.split("/");
        const dir = parts.length > 1 ? parts[0] : "(root)";
        if (!structure[dir]) structure[dir] = [];
        structure[dir].push(f.path);
      }

      return {
        owner,
        repo,
        branch,
        total_files: files.length,
        truncated: tree.truncated || false,
        structure,
        files: files.slice(0, 500),
      };
    },
  },

  fetch_github_file: {
    cli_only: true,
    description:
      "Fetch the contents of a file from a GitHub repository. CLI mode only — Cowork VMs block GitHub network access. For private repos, call github_login first.",
    inputSchema: {
      type: "object",
      properties: {
        url: {
          type: "string",
          description: "Full GitHub URL (e.g., 'https://github.com/owner/repo')",
        },
        owner: {
          type: "string",
          description: "Repository owner (alternative to url)",
        },
        repo: {
          type: "string",
          description: "Repository name (alternative to url)",
        },
        path: {
          type: "string",
          description:
            "File path within the repo (e.g., 'src/models/User.swift')",
        },
        branch: {
          type: "string",
          description: "Branch name (default: 'main')",
        },
      },
      required: ["path"],
    },
    async handler(args) {
      let owner = args.owner;
      let repo = args.repo;

      if (args.url) {
        const parsed = parseGitHubUrl(args.url);
        if (!parsed) return { error: `Could not parse GitHub URL: ${args.url}` };
        owner = parsed.owner;
        repo = parsed.repo;
      }

      if (!owner || !repo) {
        return { error: "Provide either a GitHub URL or owner + repo" };
      }

      const branch = args.branch || "main";
      const filePath = args.path;
      const apiUrl = `https://api.github.com/repos/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}/contents/${encodeURIComponent(filePath)}?ref=${encodeURIComponent(branch)}`;

      let data;
      try {
        ({ data } = await httpsGet(apiUrl));
      } catch (e) {
        if (e.message.includes("REPO_NOT_FOUND_OR_PRIVATE")) {
          return {
            error: "auth_required",
            message: `Repository ${owner}/${repo} is private. Call the github_login tool first to authenticate.`,
            action: "github_login",
          };
        }
        return { error: "request_failed", message: e.message };
      }

      const file = JSON.parse(data);

      if (file.encoding === "base64" && file.content) {
        const decoded = Buffer.from(
          file.content.replace(/\n/g, ""),
          "base64"
        ).toString("utf8");
        return {
          path: file.path,
          size: file.size,
          sha: file.sha,
          content: decoded.length > 100000 ? decoded.slice(0, 100000) + "\n...(truncated)" : decoded,
        };
      }

      // Large files: use raw download URL
      if (file.download_url) {
        try {
          const { data: rawContent } = await httpsGet(file.download_url);
          return {
            path: file.path,
            size: file.size,
            content: rawContent.length > 100000 ? rawContent.slice(0, 100000) + "\n...(truncated)" : rawContent,
          };
        } catch (e) {
          return { error: "download_failed", message: e.message, path: file.path };
        }
      }

      return { error: "Could not decode file content", details: { path: file.path, size: file.size } };
    },
  },

  fetch_github_files_batch: {
    cli_only: true,
    description:
      "Fetch multiple files from a GitHub repository in one call. CLI mode only — Cowork VMs block GitHub network access. For private repos, call github_login first.",
    inputSchema: {
      type: "object",
      properties: {
        url: {
          type: "string",
          description: "Full GitHub URL",
        },
        owner: { type: "string", description: "Repository owner" },
        repo: { type: "string", description: "Repository name" },
        paths: {
          type: "array",
          items: { type: "string" },
          description: "Array of file paths to fetch",
        },
        branch: { type: "string", description: "Branch (default: 'main')" },
      },
      required: ["paths"],
    },
    async handler(args) {
      let owner = args.owner;
      let repo = args.repo;

      if (args.url) {
        const parsed = parseGitHubUrl(args.url);
        if (!parsed) return { error: `Could not parse GitHub URL: ${args.url}` };
        owner = parsed.owner;
        repo = parsed.repo;
      }

      if (!owner || !repo) {
        return { error: "Provide either a GitHub URL or owner + repo" };
      }

      // Pre-check: test auth before fetching multiple files
      if (!getGitHubToken()) {
        return {
          error: "auth_required",
          message: `No GitHub token available. Call the github_login tool first to authenticate, then retry.`,
          action: "github_login",
        };
      }

      const branch = args.branch || "main";
      const results = [];

      for (const filePath of (args.paths || []).slice(0, 15)) {
        try {
          const apiUrl = `https://api.github.com/repos/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}/contents/${encodeURIComponent(filePath)}?ref=${encodeURIComponent(branch)}`;
          const { data } = await httpsGet(apiUrl);
          const file = JSON.parse(data);

          if (file.encoding === "base64" && file.content) {
            const decoded = Buffer.from(file.content.replace(/\n/g, ""), "base64").toString("utf8");
            results.push({
              path: file.path,
              size: file.size,
              content: decoded.length > 50000 ? decoded.slice(0, 50000) + "\n...(truncated)" : decoded,
            });
          } else {
            results.push({ path: filePath, error: "Could not decode" });
          }
        } catch (e) {
          results.push({ path: filePath, error: e.message });
        }
      }

      return { owner, repo, branch, files: results, fetched: results.length };
    },
  },
};

// ---------------------------------------------------------------------------
// JSON-RPC / MCP Protocol Handler (stdio transport, zero dependencies)
// ---------------------------------------------------------------------------

const SERVER_INFO = {
  name: "ai-prd-generator",
  version: skillConfig.version || "1.0.0",
};

function makeResponse(id, result) {
  return JSON.stringify({ jsonrpc: "2.0", id, result });
}

function makeError(id, code, message) {
  return JSON.stringify({ jsonrpc: "2.0", id, error: { code, message } });
}

async function handleRequest(msg) {
  const { id, method, params } = msg;

  switch (method) {
    case "initialize":
      return makeResponse(id, {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        serverInfo: SERVER_INFO,
      });

    case "notifications/initialized":
      return null;

    case "tools/list":
      return makeResponse(id, {
        tools: Object.entries(TOOLS)
          .filter(([, def]) => !(ENVIRONMENT === "cowork" && def.cli_only))
          .map(([name, def]) => ({
            name,
            description: def.description,
            inputSchema: def.inputSchema,
          })),
      });

    case "tools/call": {
      const toolName = (params || {}).name;
      const toolArgs = (params || {}).arguments || {};
      const tool = TOOLS[toolName];

      if (!tool) {
        return makeResponse(id, {
          content: [
            {
              type: "text",
              text: JSON.stringify({ error: `Unknown tool: ${toolName}` }, null, 2),
            },
          ],
        });
      }

      // Guard: cli_only tools called in Cowork return helpful error
      if (ENVIRONMENT === "cowork" && tool.cli_only) {
        return makeResponse(id, {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                error: "not_available_in_cowork",
                message: `The '${toolName}' tool requires network access to GitHub, which is blocked in Cowork's sandboxed VM. To analyze a codebase in Cowork, ask the user to share their local project directory instead.`,
                suggestion: "Use Glob/Grep/Read on the user's shared local directory for codebase analysis.",
              }, null, 2),
            },
          ],
          isError: true,
        });
      }

      try {
        const result = await tool.handler(toolArgs);
        return makeResponse(id, {
          content: [
            { type: "text", text: JSON.stringify(result, null, 2) },
          ],
        });
      } catch (err) {
        return makeResponse(id, {
          content: [
            {
              type: "text",
              text: JSON.stringify({ error: err.message }, null, 2),
            },
          ],
          isError: true,
        });
      }
    }

    default:
      if (id !== undefined) {
        return makeError(id, -32601, `Method not found: ${method}`);
      }
      return null;
  }
}

// ---------------------------------------------------------------------------
// stdio transport — Content-Length framing (MCP/LSP standard) + newline fallback
// ---------------------------------------------------------------------------

let buffer = "";

function sendResponse(response) {
  const bytes = Buffer.byteLength(response, "utf8");
  process.stdout.write(`Content-Length: ${bytes}\r\n\r\n${response}`);
}

function dispatch(raw) {
  try {
    const msg = JSON.parse(raw);
    handleRequest(msg).then((response) => {
      if (response) sendResponse(response);
    }).catch((e) => {
      process.stderr.write(`[ai-prd-generator] Handler error: ${e.message}\n`);
    });
  } catch (e) {
    process.stderr.write(`[ai-prd-generator] Failed to parse message: ${e.message}\n`);
  }
}

function processBuffer() {
  while (buffer.length > 0) {
    // Try Content-Length framing first (MCP/LSP standard)
    const clMatch = buffer.match(/^Content-Length:\s*(\d+)\r?\n\r?\n/);
    if (clMatch) {
      const len = parseInt(clMatch[1], 10);
      const headerLen = clMatch[0].length;
      if (buffer.length < headerLen + len) return; // wait for more data
      const message = buffer.substring(headerLen, headerLen + len);
      buffer = buffer.substring(headerLen + len);
      dispatch(message);
      continue;
    }

    // Fallback: newline-delimited JSON
    const newlineIdx = buffer.indexOf("\n");
    if (newlineIdx === -1) return; // wait for more data
    const line = buffer.substring(0, newlineIdx).trim();
    buffer = buffer.substring(newlineIdx + 1);
    if (line) dispatch(line);
  }
}

// ---------------------------------------------------------------------------
// CLI mode — direct tool invocation, no MCP protocol
// Usage: node index.js --cli <tool_name> [json_args]
// ---------------------------------------------------------------------------

if (process.argv[2] === "--cli") {
  const toolName = process.argv[3];
  const tool = TOOLS[toolName];
  if (!tool) {
    const available = Object.keys(TOOLS).join(", ");
    process.stderr.write(`Unknown tool: ${toolName}\nAvailable: ${available}\n`);
    process.exit(1);
  }
  const args = process.argv[4] ? JSON.parse(process.argv[4]) : {};
  Promise.resolve(tool.handler(args))
    .then((result) => {
      process.stdout.write(JSON.stringify(result, null, 2) + "\n");
      process.exit(0);
    })
    .catch((err) => {
      process.stdout.write(JSON.stringify({ error: err.message }, null, 2) + "\n");
      process.exit(1);
    });
} else {
  // MCP stdio server mode
  process.stdin.on("data", (chunk) => {
    buffer += chunk.toString();
    processBuffer();
  });

  process.on("SIGTERM", () => process.exit(0));
  process.on("SIGINT", () => process.exit(0));

  process.stderr.write(
    `[ai-prd-generator] MCP server started (${ENVIRONMENT} mode, v1.0.0)\n`
  );
}
