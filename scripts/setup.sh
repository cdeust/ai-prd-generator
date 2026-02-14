#!/usr/bin/env bash
set -euo pipefail

# AI PRD Generator — One-Command CLI Setup
# Installs the skill and commands into Claude Code, creates engine home.
# Run from anywhere inside the repo:  ./scripts/setup.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Colors (disabled when not a terminal)
if [ -t 1 ]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; BOLD='\033[1m'; NC='\033[0m'
else
  GREEN=''; RED=''; YELLOW=''; BOLD=''; NC=''
fi

info()  { printf "${GREEN}[OK]${NC}  %s\n" "$1"; }
warn()  { printf "${YELLOW}[!!]${NC}  %s\n" "$1"; }
fail()  { printf "${RED}[ERR]${NC} %s\n" "$1"; exit 1; }

# ── 1. Check Node.js >= 18 ──────────────────────────────────────────────────

if ! command -v node &>/dev/null; then
  fail "Node.js is not installed. Install Node.js 18+ and re-run."
fi

NODE_MAJOR=$(node -e "process.stdout.write(String(process.versions.node.split('.')[0]))")
if [ "$NODE_MAJOR" -lt 18 ]; then
  fail "Node.js $NODE_MAJOR found — version 18+ required. Please upgrade."
fi
info "Node.js $(node --version) detected"

# ── 2. Verify repo structure ────────────────────────────────────────────────

[ -f "$REPO_ROOT/skills/ai-prd-generator/SKILL.md" ] \
  || fail "Missing skills/ai-prd-generator/SKILL.md — run from the plugin repo root."
[ -f "$REPO_ROOT/skill-config.json" ] \
  || fail "Missing skill-config.json — run from the plugin repo root."
info "Plugin structure verified"

# ── 3. Install skill into Claude Code ────────────────────────────────────────

# Claude Code discovers skills from ~/.claude/skills/<name>/SKILL.md
# We symlink so the skill stays in sync with the repo.

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
mkdir -p "$SKILLS_DIR"

# Remove any existing link/directory (may be stale from previous install)
if [ -L "$SKILLS_DIR/ai-prd-generator" ] || [ -d "$SKILLS_DIR/ai-prd-generator" ]; then
  rm -rf "$SKILLS_DIR/ai-prd-generator"
fi

ln -sf "$REPO_ROOT/skills/ai-prd-generator" "$SKILLS_DIR/ai-prd-generator"
info "Skill installed → ~/.claude/skills/ai-prd-generator → repo"

# ── 4. Install commands into Claude Code ─────────────────────────────────────

# Claude Code discovers commands from ~/.claude/commands/<namespace>/name.md
# Namespace "ai-prd-generator" gives: /ai-prd-generator:validate-license, etc.

COMMANDS_DIR="$CLAUDE_DIR/commands/ai-prd-generator"
mkdir -p "$COMMANDS_DIR"

for cmd_file in "$REPO_ROOT/commands/"*.md; do
  [ -f "$cmd_file" ] || continue
  cmd_name=$(basename "$cmd_file")
  ln -sf "$cmd_file" "$COMMANDS_DIR/$cmd_name"
done
info "Commands installed → ~/.claude/commands/ai-prd-generator/"

# ── 5. Install skill-config.json ─────────────────────────────────────────────

ENGINE_HOME="$HOME/.aiprd"
mkdir -p "$ENGINE_HOME"

cp "$REPO_ROOT/skill-config.json" "$ENGINE_HOME/skill-config.json"
info "Config installed → ~/.aiprd/skill-config.json"

# ── 6. Install MCP launcher (for Cowork mode only) ──────────────────────────

# The MCP server is only used by Cowork (Claude Desktop).
# CLI Terminal mode does NOT use MCP — Claude follows SKILL.md instructions directly.

if [ -f "$REPO_ROOT/mcp-server/index.js" ]; then
  LAUNCHER="$ENGINE_HOME/run-mcp.sh"
  cat > "$LAUNCHER" << LAUNCH_EOF
#!/usr/bin/env bash
exec node "$REPO_ROOT/mcp-server/index.js" "\$@"
LAUNCH_EOF
  chmod +x "$LAUNCHER"
fi

# ── 7. Install engine config (if install-engine.sh exists) ──────────────────

if [ -f "$REPO_ROOT/scripts/install-engine.sh" ]; then
  bash "$REPO_ROOT/scripts/install-engine.sh"
  info "Engine config installed"
fi

# ── 8. Detect Swift toolchain (optional) ────────────────────────────────────

if command -v swift &>/dev/null; then
  SWIFT_VERSION=$(swift --version 2>&1 | head -1)
  info "Swift toolchain detected: $SWIFT_VERSION"
  if [ -f "$REPO_ROOT/library/Package.swift" ]; then
    printf "  To build the Swift library: ${BOLD}cd library && swift build${NC}\n"
  fi
fi

# ── 9. Build Cowork plugin ZIP ───────────────────────────────────────────────

if [ -f "$REPO_ROOT/scripts/build-cowork-zip.sh" ]; then
  bash "$REPO_ROOT/scripts/build-cowork-zip.sh"
  info "Cowork ZIP built → dist/ai-prd-generator-plugin.zip"
fi

# ── Done ────────────────────────────────────────────────────────────────────

printf "\n${BOLD}${GREEN}Setup complete!${NC}\n\n"

printf "  ${BOLD}Claude Code (CLI Terminal):${NC}\n"
printf "    The skill and commands are installed. Start ${BOLD}claude${NC} from any directory, then:\n"
printf "      ${BOLD}/ai-prd-generator:validate-license AIPRD-your-key${NC}  — activate a license\n"
printf "      ${BOLD}/ai-prd-generator:validate-license${NC}                — check license status\n"
printf "      ${BOLD}/ai-prd-generator:generate-prd${NC}                    — generate a PRD\n"
printf "      ${BOLD}/ai-prd-generator:index-codebase${NC}                  — index a codebase\n"
printf "      ${BOLD}/ai-prd-generator${NC}                                 — main skill\n"
printf "    Or just say: ${BOLD}\"validate license key AIPRD-your-key-here\"${NC}\n\n"

printf "  ${BOLD}Cowork (Claude Desktop):${NC}\n"
printf "    Upload ${BOLD}dist/ai-prd-generator-plugin.zip${NC} as a local plugin in Cowork.\n\n"
