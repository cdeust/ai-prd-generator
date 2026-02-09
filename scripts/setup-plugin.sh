#!/usr/bin/env bash
# setup-plugin.sh — Prepare the lightweight Cowork plugin shell.
#
# Copies SKILL.md + skill-config.json into the plugin directory.
# The plugin itself contains NO heavy dependencies — it points to
# the engine installed at ~/.aiprd/ (via `make install-engine`).
#
# Usage:
#   ./scripts/setup-plugin.sh          # from repo root
#   make setup-plugin                   # via Makefile

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugin"
SKILL_DEST="$PLUGIN_DIR/skills/ai-prd-generator"
MARKETPLACE_PLUGIN="$REPO_ROOT/marketplace/plugins/ai-prd-builder"
ENGINE_HOME="$HOME/.aiprd"

echo "=== AI PRD Builder — Plugin Setup ==="
echo ""

# 1. Ensure plugin directory structure
echo "[1/4] Creating plugin directory structure..."
mkdir -p "$SKILL_DEST"
mkdir -p "$PLUGIN_DIR/commands"
mkdir -p "$PLUGIN_DIR/.claude-plugin"

# 2. Copy SKILL.md into plugin
echo "[2/4] Copying SKILL.md → plugin/skills/ai-prd-generator/"
if [ -f "$REPO_ROOT/SKILL.md" ]; then
    cp "$REPO_ROOT/SKILL.md" "$SKILL_DEST/SKILL.md"
    echo "  Copied SKILL.md"
else
    echo "  WARNING: SKILL.md not found at repo root"
fi

# 3. Copy skill-config.json into plugin
echo "[3/4] Copying skill-config.json → plugin/"
if [ -f "$REPO_ROOT/skill-config.json" ]; then
    cp "$REPO_ROOT/skill-config.json" "$PLUGIN_DIR/skill-config.json"
    echo "  Copied skill-config.json"
else
    echo "  WARNING: skill-config.json not found at repo root"
fi

# 4. Mirror plugin into local marketplace (for `claude plugin install`)
echo "[4/4] Mirroring plugin into local marketplace..."
mkdir -p "$MARKETPLACE_PLUGIN"
rsync -a --delete \
    --exclude='.venv' \
    --exclude='__pycache__' \
    --exclude='.DS_Store' \
    "$PLUGIN_DIR/" "$MARKETPLACE_PLUGIN/"
echo "  Synced to marketplace/plugins/ai-prd-builder/"

# Summary
echo ""
if [ -f "$PLUGIN_DIR/mcp-server/index.js" ]; then
    echo "MCP server: bundled (Node.js, zero dependencies)"
else
    echo "WARNING: plugin/mcp-server/index.js not found"
fi
if [ -x "$ENGINE_HOME/validate-license" ]; then
    echo "Engine: installed at $ENGINE_HOME (CLI mode: full crypto validation)"
else
    echo "Engine: not installed (Cowork mode: file-based validation)"
fi

echo ""
echo "=== Plugin Setup Complete ==="
echo ""
echo "Install via Cowork:"
echo "  1. claude plugin marketplace add ./marketplace"
echo "  2. claude plugin install ai-prd-builder@ai-prd-builder-local"
echo ""
echo "Or dev mode:  make dev-plugin"
echo ""
