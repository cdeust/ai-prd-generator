#!/usr/bin/env bash
set -euo pipefail

# Build the Cowork plugin ZIP from the repository.
# Only includes what Cowork needs — no venv, node_modules, .git, build artifacts, etc.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$REPO_ROOT/dist"
PLUGIN_NAME="ai-prd-generator-plugin"
BUILD_DIR=$(mktemp -d)

trap "rm -rf '$BUILD_DIR'" EXIT

STAGE="$BUILD_DIR/$PLUGIN_NAME"
mkdir -p "$STAGE"

# Copy only what Cowork needs
cp -R "$REPO_ROOT/.claude-plugin" "$STAGE/"
cp -R "$REPO_ROOT/skills" "$STAGE/"
cp -R "$REPO_ROOT/commands" "$STAGE/"
cp "$REPO_ROOT/skill-config.json" "$STAGE/"

# Copy MCP server (without node_modules if present)
mkdir -p "$STAGE/mcp-server"
cp "$REPO_ROOT/mcp-server/index.js" "$STAGE/mcp-server/"
[ -f "$REPO_ROOT/mcp-server/package.json" ] && cp "$REPO_ROOT/mcp-server/package.json" "$STAGE/mcp-server/" || true

# Copy LICENSE if present
[ -f "$REPO_ROOT/LICENSE" ] && cp "$REPO_ROOT/LICENSE" "$STAGE/" || true

# Generate .mcp.json for Cowork (uses ${CLAUDE_PLUGIN_ROOT}/ resolved by plugin system)
cat > "$STAGE/.mcp.json" << 'MCPEOF'
{
  "mcpServers": {
    "ai-prd-generator": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp-server/index.js"]
    }
  }
}
MCPEOF

# Build ZIP — exclude any stray junk
mkdir -p "$DIST_DIR"
ZIP_PATH="$DIST_DIR/$PLUGIN_NAME.zip"
rm -f "$ZIP_PATH"
(cd "$BUILD_DIR" && zip -r "$ZIP_PATH" "$PLUGIN_NAME" \
  -x '*/.DS_Store' '*/._*' '*/.git/*' '*/node_modules/*' \
     '*/venv/*' '*/.venv/*' '*/__pycache__/*' '*/.build/*' \
     '*/.swiftpm/*' '*/DerivedData/*' '*/.env' '*/.env.*')

echo ""
echo "Cowork plugin ZIP built: $ZIP_PATH"
echo "Upload this to Cowork as a local plugin."
