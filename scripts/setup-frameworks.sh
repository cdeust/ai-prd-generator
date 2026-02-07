#!/bin/bash
# setup-frameworks.sh — Decrypt encrypted XCFrameworks for building
# Requires: valid license at ~/.aiprd/license.json
# Usage: ./scripts/setup-frameworks.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENCRYPTED_DIR="$REPO_ROOT/frameworks/encrypted"
OUTPUT_DIR="$REPO_ROOT/frameworks"
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
ENCRYPTED_DIR="$ENCRYPTED_DIR" OUTPUT_DIR="$OUTPUT_DIR" /tmp/aiprd-decrypt

echo ""
echo "  Frameworks ready at: $OUTPUT_DIR/"
echo "  You can now build with: swift build --package-path library"
echo "═══════════════════════════════════════════════════════"
