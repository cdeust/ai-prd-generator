#!/usr/bin/env bash
# install-engine.sh — Install the AI PRD Builder engine config to ~/.aiprd/
#
# Installs:
#   ~/.aiprd/skill-config.json   (config for standalone use)
#
# The plugin bundles its own Node.js MCP server (zero deps) which handles
# all license validation (Ed25519 + AES-256 encrypted persistence).
# The MCP launcher (~/.aiprd/run-mcp.sh) is created by setup.sh.
#
# Usage:
#   ./scripts/install-engine.sh       # from repo root
#   make install-engine               # via Makefile

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENGINE_HOME="$HOME/.aiprd"

echo "=== AI PRD Builder — Engine Install ==="
echo ""

# 1. Create engine directory
echo "[1/2] Creating engine directory at $ENGINE_HOME..."
mkdir -p "$ENGINE_HOME"

# 2. Copy skill-config.json (standalone fallback — plugin also ships its own)
echo "[2/2] Installing skill-config.json..."
if [ -f "$REPO_ROOT/skill-config.json" ]; then
    cp "$REPO_ROOT/skill-config.json" "$ENGINE_HOME/skill-config.json"
    echo "  Copied to $ENGINE_HOME/skill-config.json"
fi

# Summary
echo ""
echo "=== Engine Install Complete ==="
echo ""
echo "Installed to: $ENGINE_HOME"
if [ -f "$ENGINE_HOME/run-mcp.sh" ]; then
    echo "  $ENGINE_HOME/run-mcp.sh (MCP engine launcher)"
fi
if [ -f "$ENGINE_HOME/skill-config.json" ]; then
    echo "  $ENGINE_HOME/skill-config.json"
fi
echo ""
echo "The plugin's bundled Node.js MCP server handles all license validation."
echo "Next: ./scripts/setup.sh"
echo ""
