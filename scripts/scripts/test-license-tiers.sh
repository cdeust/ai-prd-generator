#!/bin/bash
# Test license tier behavior
# Usage: ./scripts/test-license-tiers.sh

set -e

cd "$(dirname "$0")/.."

echo "=========================================="
echo "AI Architect PRD Builder - License Tier Tests"
echo "=========================================="
echo ""

# Build first
echo "📦 Building library..."
cd library && swift build -q && cd ..
echo "✅ Build successful"
echo ""

# Test 1: No license (should be free tier)
echo "----------------------------------------"
echo "Test 1: No LICENSE_KEY or LICENSE_TIER"
echo "Expected: Free tier (2 strategies)"
echo "----------------------------------------"
unset LICENSE_KEY
unset LICENSE_TIER
cd library
swift run -q 2>&1 | head -20 || true
cd ..
echo ""

# Test 2: Development licensed key
echo "----------------------------------------"
echo "Test 2: LICENSE_KEY=AIPRD-DEV-2026-LICENSED"
echo "Expected: Licensed tier (15 strategies)"
echo "----------------------------------------"
export LICENSE_KEY="AIPRD-DEV-2026-LICENSED"
unset LICENSE_TIER
cd library
swift run -q 2>&1 | head -20 || true
cd ..
echo ""

# Test 3: Development free key (for testing degradation)
echo "----------------------------------------"
echo "Test 3: LICENSE_KEY=AIPRD-DEV-2026-FREE"
echo "Expected: Free tier (testing degradation)"
echo "----------------------------------------"
export LICENSE_KEY="AIPRD-DEV-2026-FREE"
unset LICENSE_TIER
cd library
swift run -q 2>&1 | head -20 || true
cd ..
echo ""

# Test 4: LICENSE_TIER=licensed
echo "----------------------------------------"
echo "Test 4: LICENSE_TIER=licensed"
echo "Expected: Licensed tier"
echo "----------------------------------------"
unset LICENSE_KEY
export LICENSE_TIER="licensed"
cd library
swift run -q 2>&1 | head -20 || true
cd ..
echo ""

# Test 5: Invalid key (should fall back to free)
echo "----------------------------------------"
echo "Test 5: LICENSE_KEY=invalid-key"
echo "Expected: Free tier (invalid key)"
echo "----------------------------------------"
export LICENSE_KEY="invalid-key"
unset LICENSE_TIER
cd library
swift run -q 2>&1 | head -20 || true
cd ..
echo ""

echo "=========================================="
echo "License Tier Tests Complete"
echo "=========================================="
echo ""
echo "Development Keys:"
echo "  AIPRD-DEV-2026-LICENSED - Full features"
echo "  AIPRD-DEV-2026-FREE     - Test free tier"
echo ""
echo "Quick Usage:"
echo "  LICENSE_KEY=AIPRD-DEV-2026-LICENSED swift run"
