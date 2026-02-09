#!/usr/bin/env node
/**
 * AI PRD Builder — Dual-Mode MCP Server (Zero Dependencies)
 *
 * Runs in two modes:
 *   CLI mode  : delegates license validation to ~/.aiprd/validate-license binary
 *   Cowork mode: uses built-in file-based validation (no hardware fingerprint)
 *
 * Environment detection is automatic via CLAUDE_PLUGIN_ROOT.
 * No external dependencies required — Node.js only.
 *
 * Transport: stdio (JSON-RPC 2.0). All logging to stderr.
 */

const fs = require("fs");
const os = require("os");
const path = require("path");
const { execSync } = require("child_process");

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
    `[ai-prd-builder] Warning: Could not load skill-config.json from ${SKILL_CONFIG_PATH}\n`
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
// License Validation — Dual Mode
// ---------------------------------------------------------------------------

function validateLicense() {
  const validatorPath = path.join(ENGINE_HOME, "validate-license");

  // CLI mode: try external binary first (full crypto: Ed25519, HMAC, hardware)
  if (fs.existsSync(validatorPath)) {
    try {
      const raw = execSync(validatorPath, {
        encoding: "utf8",
        timeout: 5000,
      });
      const result = JSON.parse(raw);
      result.environment = ENVIRONMENT;
      return result;
    } catch (e) {
      process.stderr.write(
        `[ai-prd-builder] External validator failed, falling back to in-plugin: ${e.message}\n`
      );
    }
  }

  // Cowork / fallback mode: in-plugin file-based validation
  return validateLicenseInPlugin();
}

function validateLicenseInPlugin() {
  // Check license files in order of priority
  const candidatePaths = [
    path.join(PLUGIN_ROOT, "license.json"),
    path.join(ENGINE_HOME, "license.json"),
    path.join(os.homedir(), ".ai-prd", "license.json"),
  ];

  for (const licensePath of candidatePaths) {
    if (fs.existsSync(licensePath)) {
      try {
        const license = JSON.parse(fs.readFileSync(licensePath, "utf8"));
        if (license.tier) {
          const expiresAt = new Date(license.expires_at || "2099-12-31");
          if (expiresAt > new Date()) {
            return {
              tier: license.tier,
              features: license.enabled_features || getFeaturesListForTier(license.tier),
              signature_verified: false,
              hardware_verified: false,
              expires_at: license.expires_at || null,
              days_remaining: Math.ceil(
                (expiresAt - new Date()) / 86_400_000
              ),
              source: "license_file",
              environment: ENVIRONMENT,
              errors: [],
            };
          }
        }
      } catch (_) {
        /* continue to next candidate */
      }
    }
  }

  // Check trial file
  const trialPath = path.join(ENGINE_HOME, "trial.json");
  if (fs.existsSync(trialPath)) {
    try {
      const trial = JSON.parse(fs.readFileSync(trialPath, "utf8"));
      const expiresAt = new Date(trial.trial_expires_at || trial.expires_at || 0);
      if (expiresAt > new Date()) {
        return {
          tier: "trial",
          features: getFeaturesListForTier("trial"),
          signature_verified: false,
          hardware_verified: false,
          expires_at: trial.trial_expires_at || trial.expires_at,
          days_remaining: Math.ceil((expiresAt - new Date()) / 86_400_000),
          source: "trial",
          environment: ENVIRONMENT,
          errors: [],
        };
      }
    } catch (_) {
      /* continue */
    }
  }

  // Default: free tier
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
      "Validate the current license tier. Returns tier, features, and validation details. Works in both CLI (external binary) and Cowork (in-plugin) modes.",
    inputSchema: { type: "object", properties: {}, required: [] },
    handler(_args) {
      return validateLicense();
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
        name: skillConfig.name || "AI PRD Builder",
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
      const validatorExists = fs.existsSync(
        path.join(ENGINE_HOME, "validate-license")
      );
      return {
        status: "ok",
        version: skillConfig.version || "unknown",
        environment: ENVIRONMENT,
        skill_config_loaded: Object.keys(skillConfig).length > 0,
        external_validator_available: validatorExists,
        license_mode: validatorExists ? "external_binary" : "in_plugin",
        engine_home: ENGINE_HOME,
        plugin_root: PLUGIN_ROOT,
        timestamp: new Date().toISOString(),
      };
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
};

// ---------------------------------------------------------------------------
// JSON-RPC / MCP Protocol Handler (stdio transport, zero dependencies)
// ---------------------------------------------------------------------------

const SERVER_INFO = {
  name: "ai-prd-builder",
  version: skillConfig.version || "7.2.0",
};

function makeResponse(id, result) {
  return JSON.stringify({ jsonrpc: "2.0", id, result });
}

function makeError(id, code, message) {
  return JSON.stringify({ jsonrpc: "2.0", id, error: { code, message } });
}

function handleRequest(msg) {
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
        tools: Object.entries(TOOLS).map(([name, def]) => ({
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
          isError: true,
        });
      }

      try {
        const result = tool.handler(toolArgs);
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
// stdio transport — newline-delimited JSON-RPC
// ---------------------------------------------------------------------------

let buffer = "";

process.stdin.on("data", (chunk) => {
  buffer += chunk.toString();

  let lines = buffer.split("\n");
  buffer = lines.pop(); // keep incomplete line in buffer

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("Content-Length")) continue;

    try {
      const msg = JSON.parse(trimmed);
      const response = handleRequest(msg);
      if (response) {
        process.stdout.write(response + "\n");
      }
    } catch (e) {
      process.stderr.write(
        `[ai-prd-builder] Failed to parse message: ${e.message}\n`
      );
    }
  }
});

process.on("SIGTERM", () => process.exit(0));
process.on("SIGINT", () => process.exit(0));

process.stderr.write(
  `[ai-prd-builder] MCP server started (${ENVIRONMENT} mode)\n`
);
