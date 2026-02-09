#!/usr/bin/env bash
# install-engine.sh — Install the AI PRD Builder engine to ~/.aiprd/
#
# Installs:
#   ~/.aiprd/validate-license    (compiled Swift binary for CLI crypto validation)
#   ~/.aiprd/skill-config.json   (config for standalone use)
#
# The plugin bundles its own Node.js MCP server (zero deps).
# This script only installs the CLI-mode crypto validator for
# full Ed25519 + HMAC + hardware-fingerprint license validation.
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
if [ -f "$ENGINE_HOME/validate-license" ]; then
    echo "  $ENGINE_HOME/validate-license (crypto validator)"
else
    echo "  NOTE: validate-license binary not found."
    echo "  Run 'make build-validator' to compile it (requires Swift toolchain)."
fi
if [ -f "$ENGINE_HOME/skill-config.json" ]; then
    echo "  $ENGINE_HOME/skill-config.json"
fi
echo ""
echo "The plugin's bundled Node.js MCP server handles everything else."
echo "Next: make setup-plugin && make install-plugin"
echo ""
