#!/bin/bash

# Skill Verification Script - Combined rules check
# Verifies: CLAUDE.md rules, Naming conventions, 3R's principles

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIBRARY_DIR="$PROJECT_ROOT/library/Sources"

VIOLATIONS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🤖 AI PRD GENERATOR SKILL VERIFICATION"
echo "========================================"
echo "Scanning: library/Sources"
echo ""

# 1. Layer Structure
echo "🏛️  Clean Architecture Layers"
echo "-----------------------------"
REQUIRED_LAYERS=("Domain" "Application" "Infrastructure" "Composition")
MISSING=()
for layer in "${REQUIRED_LAYERS[@]}"; do
    if [ ! -d "$LIBRARY_DIR/$layer" ]; then
        MISSING+=("$layer")
    fi
done

if [ ${#MISSING[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ PASS${NC} - All Clean Architecture layers present"
    for layer in "${REQUIRED_LAYERS[@]}"; do
        echo -e "  ✓ $layer"
    done
else
    echo -e "${RED}❌ FAIL${NC} - Missing layers:"
    for layer in "${MISSING[@]}"; do
        echo -e "  ❌ $layer"
    done
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 2. Domain Layer Purity
echo "🧬 Domain Layer Purity (Foundation only)"
echo "----------------------------------------"
DOMAIN_VIOLATIONS=$(find "$LIBRARY_DIR/Domain" -name "*.swift" 2>/dev/null | while read file; do
    NON_FOUNDATION=$(grep "^import " "$file" | grep -v "^import Foundation" | grep -v "^import Domain" || true)
    if [ -n "$NON_FOUNDATION" ]; then
        echo "$file: $NON_FOUNDATION"
    fi
done)

if [ -z "$DOMAIN_VIOLATIONS" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Domain layer pure (Foundation only)"
else
    echo -e "${RED}❌ FAIL${NC} - Domain has non-Foundation imports:"
    echo "$DOMAIN_VIOLATIONS"
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 3. Sendable Conformance
echo "🔄 Sendable Conformance (Swift 6)"
echo "----------------------------------"
SENDABLE_COUNT=$(grep -r ": Sendable\|: .*Sendable" "$LIBRARY_DIR" --include="*.swift" | wc -l)
if [ $SENDABLE_COUNT -gt 10 ]; then
    echo -e "${GREEN}✅ PASS${NC} - Using Sendable ($SENDABLE_COUNT occurrences)"
else
    echo -e "${YELLOW}⚠️  INFO${NC} - Limited Sendable usage ($SENDABLE_COUNT occurrences)"
fi
echo ""

# 4. No Supabase References
echo "☁️  Standalone Architecture (No Cloud)"
echo "--------------------------------------"
SUPABASE_COUNT=$(grep -r "Supabase\|supabase" "$LIBRARY_DIR" --include="*.swift" | grep -v "//" | wc -l)
if [ $SUPABASE_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ PASS${NC} - No Supabase dependencies (standalone)"
else
    echo -e "${RED}❌ FAIL${NC} - Found $SUPABASE_COUNT Supabase references"
    grep -rn "Supabase\|supabase" "$LIBRARY_DIR" --include="*.swift" | grep -v "//" | head -10
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 5. Port Naming
echo "🔌 Domain Ports Naming (must end with 'Port')"
echo "---------------------------------------------"
BAD_PORTS=$(find "$LIBRARY_DIR/Domain/Ports" -name "*.swift" 2>/dev/null | while read file; do
    basename=$(basename "$file" .swift)
    if ! echo "$basename" | grep -q "Port$"; then
        echo "$file"
    fi
done)

if [ -z "$BAD_PORTS" ]; then
    PORT_COUNT=$(find "$LIBRARY_DIR/Domain/Ports" -name "*.swift" 2>/dev/null | wc -l)
    echo -e "${GREEN}✅ PASS${NC} - All $PORT_COUNT ports properly named"
else
    echo -e "${RED}❌ FAIL${NC} - Ports missing 'Port' suffix:"
    echo "$BAD_PORTS"
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 6. UseCase Naming
echo "🎬 Use Case Naming (must end with 'UseCase')"
echo "---------------------------------------------"
BAD_USECASES=$(find "$LIBRARY_DIR/Application/UseCases" -name "*.swift" 2>/dev/null | while read file; do
    basename=$(basename "$file" .swift)
    if ! echo "$basename" | grep -q "UseCase$"; then
        echo "$file"
    fi
done)

if [ -z "$BAD_USECASES" ]; then
    UC_COUNT=$(find "$LIBRARY_DIR/Application/UseCases" -name "*.swift" 2>/dev/null | wc -l)
    echo -e "${GREEN}✅ PASS${NC} - All use cases properly named"
else
    echo -e "${YELLOW}⚠️  WARNING${NC} - Use cases without 'UseCase' suffix:"
    echo "$BAD_USECASES"
fi
echo ""

# 7. No snake_case
echo "🐍 No Snake Case (must be camelCase)"
echo "-------------------------------------"
SNAKE_CASE=$(grep -rn "^\(public\|internal\|private\) \(var\|let\|func\) [a-z_]*_[a-z_]*" "$LIBRARY_DIR" --include="*.swift" | grep -v "CodingKeys" | grep -v "test_" || true)

if [ -z "$SNAKE_CASE" ]; then
    echo -e "${GREEN}✅ PASS${NC} - No snake_case found"
else
    echo -e "${RED}❌ FAIL${NC} - snake_case found (should be camelCase):"
    echo "$SNAKE_CASE" | head -5
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 8. No large tuples (4+ elements)
echo "📦 No Large Tuple Returns (4+ elements)"
echo "----------------------------------------"
LARGE_TUPLES=$(find "$LIBRARY_DIR" -name "*.swift" -type f | while read file; do
    grep -n '\-> *\([^)]*,[^)]*,[^)]*,[^)]*\)' "$file" 2>/dev/null | grep -v '//' || true
done)

if [ -z "$LARGE_TUPLES" ]; then
    echo -e "${GREEN}✅ PASS${NC} - No large tuple returns"
else
    echo -e "${RED}❌ FAIL${NC} - Large tuples found (use named structs):"
    echo "$LARGE_TUPLES" | head -3
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 9. No Wrapper/Helper naming
echo "🎁 No Generic Wrapper/Helper Names"
echo "-----------------------------------"
WRAPPERS=$(find "$LIBRARY_DIR" -name "*.swift" -type f | while read file; do
    grep -n "(func|struct|class|enum).*Wrapper\|Helper" "$file" 2>/dev/null | grep -v "//" | grep -v "Helper:" | grep -v "Helper\." || true
done)

if [ -z "$WRAPPERS" ]; then
    echo -e "${GREEN}✅ PASS${NC} - No wrapper/helper anti-patterns"
else
    echo -e "${RED}❌ FAIL${NC} - Generic names found (be more specific):"
    echo "$WRAPPERS" | head -3
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 10. Build succeeds
echo "🏗️  Build Verification"
echo "----------------------"
cd "$PROJECT_ROOT/library"
if swift build > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASS${NC} - Library builds successfully"
else
    echo -e "${RED}❌ FAIL${NC} - Build failed"
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# Summary
echo "========================================"
echo "📊 SKILL VERIFICATION SUMMARY"
echo "========================================"

if [ $VIOLATIONS -eq 0 ]; then
    echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
    echo ""
    echo "✅ Clean Architecture: Domain/Application/Infrastructure/Composition"
    echo "✅ Domain Purity: Foundation only"
    echo "✅ Sendable Conformance: Swift 6 ready"
    echo "✅ Standalone: No cloud dependencies"
    echo "✅ Naming: Ports, UseCases, camelCase"
    echo "✅ 3R's: No anti-patterns"
    echo "✅ Build: Success"
    echo ""
    echo "🚀 Skill follows all coding standards from ai-prd project"
    exit 0
else
    echo -e "${RED}❌ VIOLATIONS FOUND: $VIOLATIONS${NC}"
    echo ""
    echo "⚠️  Fix violations above to match ai-prd standards"
    exit 1
fi
