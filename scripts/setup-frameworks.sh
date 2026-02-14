#!/bin/bash
# setup-frameworks.sh — Decrypt encrypted XCFrameworks for building
# Requires: valid license at ~/.aiprd/license.json
# Usage: ./scripts/setup-frameworks.sh
set -euo pipefail

# Note: This script is designed for the PUBLIC repo (ai-prd-generator) where it lives at scripts/
# In the private repo, use `make decrypt` instead
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENCRYPTED_DIR="$REPO_ROOT/frameworks/encrypted"
OUTPUT_DIR="$REPO_ROOT/frameworks"
PACKAGES_DIR="$REPO_ROOT/packages"
LICENSE_PATH="$HOME/.aiprd/license.json"

echo "═══════════════════════════════════════════════════════"
echo "  AIPRD Framework Setup"
echo "═══════════════════════════════════════════════════════"
echo ""

# Check license
if [ ! -f "$LICENSE_PATH" ]; then
    echo "❌ License not found at: $LICENSE_PATH"
    echo ""
    echo "   A valid license is required to decrypt the engine frameworks."
    echo "   Purchase a license at https://ai-architect.tools"
    echo "   Then activate it with the CLI plugin's /activate-license command."
    echo ""
    exit 1
fi

# Check encrypted frameworks
if [ ! -d "$ENCRYPTED_DIR" ]; then
    echo "❌ Encrypted frameworks not found at: $ENCRYPTED_DIR"
    exit 1
fi

echo "  License: $(python3 -c "import json; print(json.load(open('$LICENSE_PATH'))['license_id'])" 2>/dev/null || echo "found")"
echo "  Decrypting frameworks..."
echo ""

# Compile and run decryption
swiftc -o /tmp/aiprd-decrypt "$REPO_ROOT/scripts/decrypt-frameworks.swift" -framework IOKit 2>/dev/null
ENCRYPTED_DIR="$ENCRYPTED_DIR" OUTPUT_DIR="$OUTPUT_DIR" PACKAGES_DIR="$PACKAGES_DIR" /tmp/aiprd-decrypt

echo ""
echo "  Frameworks ready at: $OUTPUT_DIR/"
if [ -d "$PACKAGES_DIR/AIPRDVisionEngineApple" ]; then
    echo "  Source packages at:  $PACKAGES_DIR/"
fi
echo "  You can now build with: swift build --package-path library"
echo "═══════════════════════════════════════════════════════"
