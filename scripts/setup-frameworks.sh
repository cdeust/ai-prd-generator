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
    echo "   To set up your license:"
    echo "   1. Run: swiftc -o /tmp/generate-keypair scripts/generate-keypair.swift"
    echo "   2. Run: swiftc -o /tmp/generate-license scripts/generate-license.swift -framework IOKit"
    echo "   3. Run: /tmp/generate-license"
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
