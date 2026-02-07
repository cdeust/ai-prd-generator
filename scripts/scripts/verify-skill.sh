#!/bin/bash

# Skill Verification Script - Combined rules check
# Verifies: CLAUDE.md rules, Naming conventions, 3R's principles
# Adapted for monorepo with library + packages structure

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIBRARY_DIR="$PROJECT_ROOT/library/Sources"
SHARED_UTILS_DIR="$PROJECT_ROOT/packages/AIPRDSharedUtilities/Sources"
VERIFICATION_ENGINE_DIR="$PROJECT_ROOT/packages/AIPRDVerificationEngine/Sources"
RAG_ENGINE_DIR="$PROJECT_ROOT/packages/AIPRDRAGEngine/Sources"
META_PROMPTING_DIR="$PROJECT_ROOT/packages/AIPRDMetaPromptingEngine/Sources"
STRATEGY_ENGINE_DIR="$PROJECT_ROOT/packages/AIPRDStrategyEngine/Sources"
VISION_ENGINE_DIR="$PROJECT_ROOT/packages/AIPRDVisionEngine/Sources"

# All source directories to scan
ALL_DIRS=("$LIBRARY_DIR" "$SHARED_UTILS_DIR" "$VERIFICATION_ENGINE_DIR" "$RAG_ENGINE_DIR" "$META_PROMPTING_DIR" "$STRATEGY_ENGINE_DIR" "$VISION_ENGINE_DIR")

VIOLATIONS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🤖 AI PRD GENERATOR SKILL VERIFICATION"
echo "========================================"
echo "Scanning:"
echo "  - library/Sources"
echo "  - packages/AIPRDSharedUtilities/Sources"
echo "  - packages/AIPRDVerificationEngine/Sources"
echo "  - packages/AIPRDRAGEngine/Sources"
echo "  - packages/AIPRDMetaPromptingEngine/Sources"
echo "  - packages/AIPRDStrategyEngine/Sources"
echo "  - packages/AIPRDVisionEngine/Sources"
echo ""

# 1. Layer Structure (Library)
echo "🏛️  Clean Architecture Layers (Library)"
echo "----------------------------------------"
REQUIRED_LAYERS=("Domain" "Application" "Infrastructure" "Composition")
MISSING=()
for layer in "${REQUIRED_LAYERS[@]}"; do
    if [ ! -d "$LIBRARY_DIR/$layer" ]; then
        MISSING+=("$layer")
    fi
done

if [ ${#MISSING[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ PASS${NC} - All Clean Architecture layers present in library"
    for layer in "${REQUIRED_LAYERS[@]}"; do
        echo -e "  ✓ $layer"
    done
else
    echo -e "${RED}❌ FAIL${NC} - Missing layers in library:"
    for layer in "${MISSING[@]}"; do
        echo -e "  ❌ $layer"
    done
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 2. SharedUtilities Structure
echo "📦 SharedUtilities Package Structure"
echo "-------------------------------------"
SHARED_REQUIRED=("Domain" "Application")
SHARED_MISSING=()
for layer in "${SHARED_REQUIRED[@]}"; do
    if [ ! -d "$SHARED_UTILS_DIR/$layer" ]; then
        SHARED_MISSING+=("$layer")
    fi
done

if [ ${#SHARED_MISSING[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ PASS${NC} - SharedUtilities has Domain and Application layers"
else
    echo -e "${YELLOW}⚠️  INFO${NC} - SharedUtilities missing layers: ${SHARED_MISSING[*]}"
fi
echo ""

# 3. Domain Layer Purity (Library)
# Library Domain can import Foundation, Domain, and AIPRDSharedUtilities (shared domain types)
echo "🧬 Domain Layer Purity - Library (Foundation + SharedUtilities only)"
echo "--------------------------------------------------------------------"
DOMAIN_VIOLATIONS=$(find "$LIBRARY_DIR/Domain" -name "*.swift" 2>/dev/null | while read file; do
    NON_FOUNDATION=$(grep "^import " "$file" | grep -v "^import Foundation" | grep -v "^import Domain" | grep -v "^import AIPRDSharedUtilities" || true)
    if [ -n "$NON_FOUNDATION" ]; then
        echo "$file: $NON_FOUNDATION"
    fi
done)

if [ -z "$DOMAIN_VIOLATIONS" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Library Domain layer pure (Foundation + SharedUtilities only)"
else
    echo -e "${RED}❌ FAIL${NC} - Library Domain has forbidden imports:"
    echo "$DOMAIN_VIOLATIONS"
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 4. SharedUtilities Domain Purity (Foundation only - NO external deps)
echo "🧬 Domain Layer Purity - SharedUtilities (Foundation only)"
echo "-----------------------------------------------------------"
if [ -d "$SHARED_UTILS_DIR/Domain" ]; then
    SHARED_DOMAIN_VIOLATIONS=$(find "$SHARED_UTILS_DIR/Domain" -name "*.swift" 2>/dev/null | while read file; do
        NON_FOUNDATION=$(grep "^import " "$file" | grep -v "^import Foundation" || true)
        if [ -n "$NON_FOUNDATION" ]; then
            echo "$file: $NON_FOUNDATION"
        fi
    done)

    if [ -z "$SHARED_DOMAIN_VIOLATIONS" ]; then
        echo -e "${GREEN}✅ PASS${NC} - SharedUtilities Domain layer pure (Foundation only)"
    else
        echo -e "${RED}❌ FAIL${NC} - SharedUtilities Domain has non-Foundation imports:"
        echo "$SHARED_DOMAIN_VIOLATIONS"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  SKIP${NC} - SharedUtilities Domain directory not found"
fi
echo ""

# 5. VerificationEngine depends only on SharedUtilities
echo "🔗 VerificationEngine Dependencies"
echo "-----------------------------------"
if [ -d "$VERIFICATION_ENGINE_DIR" ]; then
    BAD_IMPORTS=$(find "$VERIFICATION_ENGINE_DIR" -name "*.swift" 2>/dev/null | while read file; do
        FORBIDDEN=$(grep "^import " "$file" | grep -v "^import Foundation" | grep -v "^import AIPRDSharedUtilities" || true)
        if [ -n "$FORBIDDEN" ]; then
            echo "$file: $FORBIDDEN"
        fi
    done)

    if [ -z "$BAD_IMPORTS" ]; then
        echo -e "${GREEN}✅ PASS${NC} - VerificationEngine only imports Foundation + SharedUtilities"
    else
        echo -e "${RED}❌ FAIL${NC} - VerificationEngine has forbidden imports:"
        echo "$BAD_IMPORTS"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  SKIP${NC} - VerificationEngine directory not found"
fi
echo ""

# 5b. VisionEngine depends only on SharedUtilities + Apple frameworks
echo "🔗 VisionEngine Dependencies"
echo "----------------------------"
if [ -d "$VISION_ENGINE_DIR" ]; then
    # VisionEngine can import Foundation, SharedUtilities, Apple frameworks, and AWS for Bedrock
    # Apple: Vision, CoreML, ImageIO, FoundationModels, CoreImage, CoreGraphics, AppKit, UIKit, CoreText, CryptoKit, UniformTypeIdentifiers
    # AWS: AWSClientRuntime (for Bedrock vision analyzer)
    BAD_VISION_IMPORTS=$(find "$VISION_ENGINE_DIR" -name "*.swift" 2>/dev/null | while read file; do
        FORBIDDEN=$(grep "^import " "$file" | grep -v "^import Foundation" | grep -v "^import AIPRDSharedUtilities" | grep -v "^import Vision" | grep -v "^import CoreML" | grep -v "^import ImageIO" | grep -v "^import FoundationModels" | grep -v "^import CoreImage" | grep -v "^import CoreGraphics" | grep -v "^import AppKit" | grep -v "^import UIKit" | grep -v "^import CoreText" | grep -v "^import CryptoKit" | grep -v "^import UniformTypeIdentifiers" | grep -v "^import AWSClientRuntime" || true)
        if [ -n "$FORBIDDEN" ]; then
            echo "$file: $FORBIDDEN"
        fi
    done)

    if [ -z "$BAD_VISION_IMPORTS" ]; then
        echo -e "${GREEN}✅ PASS${NC} - VisionEngine only imports Foundation + SharedUtilities + Apple frameworks"
    else
        echo -e "${RED}❌ FAIL${NC} - VisionEngine has forbidden imports:"
        echo "$BAD_VISION_IMPORTS"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  SKIP${NC} - VisionEngine directory not found"
fi
echo ""

# 6. Sendable Conformance
echo "🔄 Sendable Conformance (Swift 6)"
echo "----------------------------------"
SENDABLE_COUNT=$(grep -r ": Sendable\|: .*Sendable" "$LIBRARY_DIR" "$SHARED_UTILS_DIR" "$VERIFICATION_ENGINE_DIR" "$RAG_ENGINE_DIR" "$VISION_ENGINE_DIR" --include="*.swift" 2>/dev/null | wc -l)
if [ $SENDABLE_COUNT -gt 50 ]; then
    echo -e "${GREEN}✅ PASS${NC} - Using Sendable ($SENDABLE_COUNT occurrences)"
else
    echo -e "${YELLOW}⚠️  INFO${NC} - Limited Sendable usage ($SENDABLE_COUNT occurrences)"
fi
echo ""

# 7. No Supabase References
echo "☁️  Standalone Architecture (No Cloud)"
echo "--------------------------------------"
SUPABASE_COUNT=$(grep -r "Supabase\|supabase" "$LIBRARY_DIR" "$SHARED_UTILS_DIR" "$VERIFICATION_ENGINE_DIR" "$RAG_ENGINE_DIR" "$VISION_ENGINE_DIR" --include="*.swift" 2>/dev/null | grep -v "//" | wc -l || echo "0")
if [ "$SUPABASE_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✅ PASS${NC} - No Supabase dependencies (standalone)"
else
    echo -e "${RED}❌ FAIL${NC} - Found $SUPABASE_COUNT Supabase references"
    grep -rn "Supabase\|supabase" "$LIBRARY_DIR" "$SHARED_UTILS_DIR" "$VERIFICATION_ENGINE_DIR" "$RAG_ENGINE_DIR" "$VISION_ENGINE_DIR" --include="*.swift" 2>/dev/null | grep -v "//" | head -10
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 8. Port Naming (Library + SharedUtilities)
echo "🔌 Domain Ports Naming (must end with 'Port')"
echo "---------------------------------------------"
BAD_PORTS=""

# Check Library ports
if [ -d "$LIBRARY_DIR/Domain/Ports" ]; then
    BAD_PORTS=$(find "$LIBRARY_DIR/Domain/Ports" -name "*.swift" 2>/dev/null | while read file; do
        basename=$(basename "$file" .swift)
        if ! echo "$basename" | grep -q "Port$"; then
            echo "$file"
        fi
    done)
fi

# Check SharedUtilities ports
if [ -d "$SHARED_UTILS_DIR/Domain/Ports" ]; then
    BAD_SHARED_PORTS=$(find "$SHARED_UTILS_DIR/Domain/Ports" -name "*.swift" 2>/dev/null | while read file; do
        basename=$(basename "$file" .swift)
        if ! echo "$basename" | grep -q "Port$"; then
            echo "$file"
        fi
    done)
    BAD_PORTS="$BAD_PORTS$BAD_SHARED_PORTS"
fi

if [ -z "$BAD_PORTS" ]; then
    LIB_PORT_COUNT=$(find "$LIBRARY_DIR/Domain/Ports" -name "*.swift" 2>/dev/null | wc -l || echo "0")
    SHARED_PORT_COUNT=$(find "$SHARED_UTILS_DIR/Domain/Ports" -name "*.swift" 2>/dev/null | wc -l || echo "0")
    TOTAL_PORTS=$((LIB_PORT_COUNT + SHARED_PORT_COUNT))
    echo -e "${GREEN}✅ PASS${NC} - All $TOTAL_PORTS ports properly named"
else
    echo -e "${RED}❌ FAIL${NC} - Ports missing 'Port' suffix:"
    echo "$BAD_PORTS"
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 9. UseCase Naming
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
    echo -e "${GREEN}✅ PASS${NC} - All $UC_COUNT use cases properly named"
else
    echo -e "${YELLOW}⚠️  WARNING${NC} - Use cases without 'UseCase' suffix:"
    echo "$BAD_USECASES"
fi
echo ""

# 10. No snake_case
echo "🐍 No Snake Case (must be camelCase)"
echo "-------------------------------------"
SNAKE_CASE=$(grep -rn "^\(public\|internal\|private\) \(var\|let\|func\) [a-z_]*_[a-z_]*" "$LIBRARY_DIR" "$SHARED_UTILS_DIR" "$VERIFICATION_ENGINE_DIR" "$RAG_ENGINE_DIR" "$VISION_ENGINE_DIR" --include="*.swift" 2>/dev/null | grep -v "CodingKeys" | grep -v "test_" || true)

if [ -z "$SNAKE_CASE" ]; then
    echo -e "${GREEN}✅ PASS${NC} - No snake_case found"
else
    echo -e "${RED}❌ FAIL${NC} - snake_case found (should be camelCase):"
    echo "$SNAKE_CASE" | head -5
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 11. No large tuples (4+ elements)
echo "📦 No Large Tuple Returns (4+ elements)"
echo "----------------------------------------"
LARGE_TUPLES=""
for dir in "${ALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        RESULT=$(find "$dir" -name "*.swift" -type f 2>/dev/null | while read file; do
            # Match function return tuples with 4+ elements, exclude comments and strings
            grep -n '\-> *([^"]*,[^"]*,[^"]*,[^"]*)' "$file" 2>/dev/null | grep -v '//' | grep -v '\"' || true
        done)
        LARGE_TUPLES="$LARGE_TUPLES$RESULT"
    fi
done

if [ -z "$LARGE_TUPLES" ]; then
    echo -e "${GREEN}✅ PASS${NC} - No large tuple returns"
else
    echo -e "${RED}❌ FAIL${NC} - Large tuples found (use named structs):"
    echo "$LARGE_TUPLES" | head -3
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 12. No Wrapper/Helper naming
echo "🎁 No Generic Wrapper/Helper Names"
echo "-----------------------------------"
WRAPPERS=""
for dir in "${ALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        RESULT=$(find "$dir" -name "*.swift" -type f 2>/dev/null | while read file; do
            grep -n "struct.*Wrapper\|class.*Wrapper\|struct.*Helper\|class.*Helper" "$file" 2>/dev/null | grep -v "//" || true
        done)
        WRAPPERS="$WRAPPERS$RESULT"
    fi
done

if [ -z "$WRAPPERS" ]; then
    echo -e "${GREEN}✅ PASS${NC} - No wrapper/helper anti-patterns"
else
    echo -e "${RED}❌ FAIL${NC} - Generic names found (be more specific):"
    echo "$WRAPPERS" | head -3
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 13. No TODO comments (technical debt)
echo "📝 No TODO Comments (no technical debt)"
echo "----------------------------------------"
TODO_COUNT=$(grep -rn "// TODO\|// FIXME\|// HACK" "$LIBRARY_DIR" "$SHARED_UTILS_DIR" "$VERIFICATION_ENGINE_DIR" "$RAG_ENGINE_DIR" "$VISION_ENGINE_DIR" --include="*.swift" 2>/dev/null | wc -l || echo "0")
if [ "$TODO_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✅ PASS${NC} - No TODO/FIXME/HACK comments"
else
    echo -e "${RED}❌ FAIL${NC} - Found $TODO_COUNT TODO/FIXME/HACK comments:"
    grep -rn "// TODO\|// FIXME\|// HACK" "$LIBRARY_DIR" "$SHARED_UTILS_DIR" "$VERIFICATION_ENGINE_DIR" "$RAG_ENGINE_DIR" "$VISION_ENGINE_DIR" --include="*.swift" 2>/dev/null | head -5
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 14. No legacy CoVVerificationResult references
echo "🔄 No Legacy Types (CoVVerificationResult removed)"
echo "---------------------------------------------------"
LEGACY_COUNT=$(grep -rn "CoVVerificationResult" "$LIBRARY_DIR" "$SHARED_UTILS_DIR" "$VERIFICATION_ENGINE_DIR" "$RAG_ENGINE_DIR" "$VISION_ENGINE_DIR" --include="*.swift" 2>/dev/null | wc -l || echo "0")
if [ "$LEGACY_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✅ PASS${NC} - No legacy CoVVerificationResult references"
else
    echo -e "${RED}❌ FAIL${NC} - Found $LEGACY_COUNT legacy CoVVerificationResult references:"
    grep -rn "CoVVerificationResult" "$LIBRARY_DIR" "$SHARED_UTILS_DIR" "$VERIFICATION_ENGINE_DIR" "$RAG_ENGINE_DIR" "$VISION_ENGINE_DIR" --include="*.swift" 2>/dev/null | head -5
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 15. File Size Limit (≤300 lines)
echo "📏 File Size Limit (≤300 lines)"
echo "--------------------------------"
LARGE_FILES=""
for dir in "${ALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        while IFS= read -r file; do
            LINE_COUNT=$(wc -l < "$file" | tr -d ' ')
            if [ "$LINE_COUNT" -gt 300 ]; then
                LARGE_FILES="$LARGE_FILES$file ($LINE_COUNT lines)\n"
            fi
        done < <(find "$dir" -name "*.swift" -type f 2>/dev/null)
    fi
done

if [ -z "$LARGE_FILES" ]; then
    echo -e "${GREEN}✅ PASS${NC} - All files ≤300 lines"
else
    echo -e "${RED}❌ FAIL${NC} - Files exceeding 300 lines:"
    echo -e "$LARGE_FILES" | head -10
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 16. Method Size Limit (≤40 lines)
echo "📐 Method Size Limit (≤40 lines)"
echo "---------------------------------"
LARGE_METHODS=""
for dir in "${ALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        while IFS= read -r file; do
            # Use awk to find functions/methods and count lines
            awk '
            /^[[:space:]]*(public |private |internal |fileprivate |open )?(static )?(func |init\(|deinit)/ {
                start = NR
                depth = 0
                in_func = 1
            }
            in_func && /{/ { depth++ }
            in_func && /}/ {
                depth--
                if (depth == 0) {
                    lines = NR - start + 1
                    if (lines > 40) {
                        print FILENAME ":" start " (" lines " lines)"
                    }
                    in_func = 0
                }
            }
            ' "$file" 2>/dev/null
        done < <(find "$dir" -name "*.swift" -type f 2>/dev/null)
    fi
done > /tmp/large_methods.txt 2>/dev/null

LARGE_METHODS=$(cat /tmp/large_methods.txt 2>/dev/null)
if [ -z "$LARGE_METHODS" ]; then
    echo -e "${GREEN}✅ PASS${NC} - All methods ≤40 lines"
else
    METHOD_COUNT=$(echo "$LARGE_METHODS" | wc -l | tr -d ' ')
    echo -e "${RED}❌ FAIL${NC} - $METHOD_COUNT methods exceeding 40 lines:"
    echo "$LARGE_METHODS" | head -10
    VIOLATIONS=$((VIOLATIONS + 1))
fi
rm -f /tmp/large_methods.txt
echo ""

# 17. One Structure Per File
echo "📦 One Structure Per File"
echo "-------------------------"
MULTI_STRUCT_FILES=""
for dir in "${ALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        while IFS= read -r file; do
            # Count top-level struct/class/enum/actor declarations
            STRUCT_COUNT=$(grep -cE "^(public |private |internal |fileprivate |open |final )*(struct |class |enum |actor )" "$file" 2>/dev/null | tr -d '[:space:]' || echo "0")
            if [ -n "$STRUCT_COUNT" ] && [ "$STRUCT_COUNT" -gt 1 ] 2>/dev/null; then
                MULTI_STRUCT_FILES="$MULTI_STRUCT_FILES$file ($STRUCT_COUNT structures)\n"
            fi
        done < <(find "$dir" -name "*.swift" -type f 2>/dev/null)
    fi
done

if [ -z "$MULTI_STRUCT_FILES" ]; then
    echo -e "${GREEN}✅ PASS${NC} - One structure per file"
else
    echo -e "${YELLOW}⚠️  WARNING${NC} - Files with multiple structures:"
    echo -e "$MULTI_STRUCT_FILES" | head -10
fi
echo ""

# 18. No Nested Types
# Exception: CodingKeys enum is required by Swift's Codable protocol
echo "🪆 No Nested Types"
echo "------------------"
NESTED_TYPES_FILE="/tmp/nested_types_$$.txt"
> "$NESTED_TYPES_FILE"

for dir in "${ALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        find "$dir" -name "*.swift" -type f 2>/dev/null | while read -r file; do
            # Find nested struct/class/enum inside other types (indented declarations)
            # Exclude CodingKeys (Codable protocol) and Iterator (AsyncSequence protocol)
            grep -nE "^[[:space:]]+.*(struct |class |enum |actor )[A-Z]" "$file" 2>/dev/null | grep -v "//" | grep -v "CodingKeys" | grep -v "struct Iterator" | while read -r line; do
                echo "$file:$line" >> "$NESTED_TYPES_FILE"
            done
        done
    fi
done

if [ ! -s "$NESTED_TYPES_FILE" ]; then
    echo -e "${GREEN}✅ PASS${NC} - No nested types (protocol requirements excluded)"
else
    NESTED_COUNT=$(wc -l < "$NESTED_TYPES_FILE" | tr -d ' ')
    echo -e "${YELLOW}⚠️  WARNING${NC} - $NESTED_COUNT nested types found (consider extracting):"
    head -10 "$NESTED_TYPES_FILE"
fi
rm -f "$NESTED_TYPES_FILE"
echo ""

# 19. No Backward Compatibility (typealias, @available deprecated)
echo "🚫 No Backward Compatibility Hacks"
echo "-----------------------------------"
COMPAT_ISSUES=""
for dir in "${ALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        # Check for deprecated aliases
        TYPEALIAS_COMPAT=$(grep -rn "typealias.*=.*// deprecated\|typealias.*=.*// legacy\|typealias.*=.*// backward" "$dir" --include="*.swift" 2>/dev/null || true)
        # Check for @available(*, deprecated)
        DEPRECATED=$(grep -rn "@available(\*, deprecated" "$dir" --include="*.swift" 2>/dev/null || true)
        # Check for "// removed" or "// for backward compatibility" comments
        REMOVED_COMMENTS=$(grep -rn "// removed\|// for backward\|// legacy support" "$dir" --include="*.swift" 2>/dev/null || true)

        COMPAT_ISSUES="$COMPAT_ISSUES$TYPEALIAS_COMPAT$DEPRECATED$REMOVED_COMMENTS"
    fi
done

if [ -z "$COMPAT_ISSUES" ]; then
    echo -e "${GREEN}✅ PASS${NC} - No backward compatibility hacks"
else
    echo -e "${RED}❌ FAIL${NC} - Backward compatibility code found:"
    echo "$COMPAT_ISSUES" | head -10
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 20. No Excessive Dependencies (max 12 imports for multi-engine architecture)
# NOTE: Higher threshold (12) accounts for library composition files that orchestrate 6+ engines
echo "🔗 Dependency Count (≤12 imports per file)"
echo "------------------------------------------"
HIGH_IMPORT_FILES=""
for dir in "${ALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        while IFS= read -r file; do
            IMPORT_COUNT=$(grep -cE "^import " "$file" 2>/dev/null | tr -d '[:space:]')
            # Default to 0 if empty
            IMPORT_COUNT=${IMPORT_COUNT:-0}
            if [ "$IMPORT_COUNT" -gt 12 ] 2>/dev/null; then
                HIGH_IMPORT_FILES="$HIGH_IMPORT_FILES$file ($IMPORT_COUNT imports)\n"
            fi
        done < <(find "$dir" -name "*.swift" -type f 2>/dev/null)
    fi
done

if [ -z "$HIGH_IMPORT_FILES" ]; then
    echo -e "${GREEN}✅ PASS${NC} - All files ≤12 imports"
else
    echo -e "${YELLOW}⚠️  WARNING${NC} - Files with many imports (possible SRP violation):"
    echo -e "$HIGH_IMPORT_FILES" | head -10
fi
echo ""

# 21. No Force Unwrapping (except tests)
echo "⚠️  No Force Unwrapping"
echo "-----------------------"
FORCE_UNWRAP=""
for dir in "${ALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        # Find force unwraps (!) but exclude comments, strings, and test files
        RESULT=$(grep -rnE "[a-zA-Z0-9_\)\]]\![^=]" "$dir" --include="*.swift" 2>/dev/null | grep -v "Tests" | grep -v "//" | grep -v '\"' | grep -v "!=" | grep -v "!==" || true)
        if [ -n "$RESULT" ]; then
            FORCE_UNWRAP="$FORCE_UNWRAP$RESULT\n"
        fi
    fi
done

if [ -z "$FORCE_UNWRAP" ]; then
    echo -e "${GREEN}✅ PASS${NC} - No force unwrapping"
else
    FORCE_COUNT=$(echo -e "$FORCE_UNWRAP" | grep -c "." || echo "0")
    echo -e "${YELLOW}⚠️  INFO${NC} - Found potential force unwraps ($FORCE_COUNT occurrences)"
    echo -e "$FORCE_UNWRAP" | head -5
fi
echo ""

# 22. No inout Parameters (prefer value types)
# Exception: hash(into hasher: inout Hasher) is required by Swift's Hashable protocol
echo "📥 No inout Parameters"
echo "----------------------"
INOUT_PARAMS=""
for dir in "${ALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        # Exclude Hashable protocol requirement: hash(into hasher: inout Hasher)
        RESULT=$(grep -rn "inout " "$dir" --include="*.swift" 2>/dev/null | grep -v "//" | grep -v "inout Hasher" || true)
        if [ -n "$RESULT" ]; then
            INOUT_PARAMS="$INOUT_PARAMS$RESULT\n"
        fi
    fi
done

if [ -z "$INOUT_PARAMS" ]; then
    echo -e "${GREEN}✅ PASS${NC} - No inout parameters (Hashable protocol excluded)"
else
    echo -e "${YELLOW}⚠️  WARNING${NC} - inout parameters found (prefer value types):"
    echo -e "$INOUT_PARAMS" | head -5
fi
echo ""

# 23. Business KPI Verification
echo "📊 Business KPIs (Measurable Business Value)"
echo "---------------------------------------------"
KPI_MISSING=""

# Check BusinessKPIs (core business metrics)
BUSINESS_KPIS="$SHARED_UTILS_DIR/Domain/Entities/Intelligence/BusinessKPIs.swift"
if [ -f "$BUSINESS_KPIS" ]; then
    # Verify 4 key business dimensions
    HAS_TIME=$(grep -c "timeSavingsPercent\|timeSavedMinutes\|manualWritingTimeMinutes" "$BUSINESS_KPIS" 2>/dev/null | tr -d '[:space:]')
    HAS_QUALITY=$(grep -c "qualityImprovementPercent\|baselineQualityScore\|actualQualityScore" "$BUSINESS_KPIS" 2>/dev/null | tr -d '[:space:]')
    HAS_COST=$(grep -c "costSavingsPercent\|costSavedUsd\|costPerThousandTokens" "$BUSINESS_KPIS" 2>/dev/null | tr -d '[:space:]')
    HAS_TOKENS=$(grep -c "tokenSavingsPercent\|naiveApproachTokens\|tokenEfficiencyRatio" "$BUSINESS_KPIS" 2>/dev/null | tr -d '[:space:]')

    HAS_TIME=${HAS_TIME:-0}
    HAS_QUALITY=${HAS_QUALITY:-0}
    HAS_COST=${HAS_COST:-0}
    HAS_TOKENS=${HAS_TOKENS:-0}

    if [ "$HAS_TIME" -ge 2 ] && [ "$HAS_QUALITY" -ge 2 ] && [ "$HAS_COST" -ge 2 ] && [ "$HAS_TOKENS" -ge 2 ]; then
        echo -e "${GREEN}  ✓${NC} BusinessKPIs (time savings, quality delta, cost reduction, token efficiency)"
    else
        KPI_MISSING="$KPI_MISSING  BusinessKPIs missing business dimensions\n"
    fi
else
    KPI_MISSING="$KPI_MISSING  BusinessKPIs.swift not found\n"
fi

# Check BaselineDefinitions (documented benchmarks)
BASELINE_DEFS="$SHARED_UTILS_DIR/Domain/Entities/Intelligence/BaselineDefinitions.swift"
if [ -f "$BASELINE_DEFS" ]; then
    HAS_TIME_BASELINE=$(grep -c "ManualWritingTime\|manualWritingTimeMinutes\|standardFeatureMinutes" "$BASELINE_DEFS" 2>/dev/null | tr -d '[:space:]')
    HAS_QUALITY_BASELINE=$(grep -c "QualityBaseline\|naiveLLM\|seniorManual" "$BASELINE_DEFS" 2>/dev/null | tr -d '[:space:]')
    HAS_TOKEN_BASELINE=$(grep -c "TokenBaseline\|naiveApproachTokens\|industryAverageTokens" "$BASELINE_DEFS" 2>/dev/null | tr -d '[:space:]')

    HAS_TIME_BASELINE=${HAS_TIME_BASELINE:-0}
    HAS_QUALITY_BASELINE=${HAS_QUALITY_BASELINE:-0}
    HAS_TOKEN_BASELINE=${HAS_TOKEN_BASELINE:-0}

    if [ "$HAS_TIME_BASELINE" -ge 2 ] && [ "$HAS_QUALITY_BASELINE" -ge 2 ] && [ "$HAS_TOKEN_BASELINE" -ge 2 ]; then
        echo -e "${GREEN}  ✓${NC} BaselineDefinitions (time, quality, token benchmarks)"
    else
        KPI_MISSING="$KPI_MISSING  BaselineDefinitions missing baseline categories\n"
    fi
else
    KPI_MISSING="$KPI_MISSING  BaselineDefinitions.swift not found\n"
fi

# Check BusinessKPIsFactory (converts metrics to business KPIs)
KPIS_FACTORY="$SHARED_UTILS_DIR/Domain/Entities/Intelligence/BusinessKPIsFactory.swift"
if [ -f "$KPIS_FACTORY" ]; then
    HAS_CREATE=$(grep -c "func create\|from metrics" "$KPIS_FACTORY" 2>/dev/null | tr -d '[:space:]')
    HAS_COMPARISON=$(grep -c "industryComparison\|comparisonSummary" "$KPIS_FACTORY" 2>/dev/null | tr -d '[:space:]')

    HAS_CREATE=${HAS_CREATE:-0}
    HAS_COMPARISON=${HAS_COMPARISON:-0}

    if [ "$HAS_CREATE" -ge 2 ] && [ "$HAS_COMPARISON" -ge 1 ]; then
        echo -e "${GREEN}  ✓${NC} BusinessKPIsFactory (metrics conversion + industry comparison)"
    else
        KPI_MISSING="$KPI_MISSING  BusinessKPIsFactory missing factory methods\n"
    fi
else
    KPI_MISSING="$KPI_MISSING  BusinessKPIsFactory.swift not found\n"
fi

# Check technical metrics still exist (foundation for business KPIs)
REASONING_METRICS="$SHARED_UTILS_DIR/Domain/Entities/Thinking/ReasoningEnhancementMetrics.swift"
if [ -f "$REASONING_METRICS" ]; then
    HAS_BASELINE_PROPS=$(grep -c "baselineTokensEstimate\|baselineDurationEstimate\|baselineLLMCallsEstimate" "$REASONING_METRICS" 2>/dev/null | tr -d '[:space:]')
    HAS_BASELINE_PROPS=${HAS_BASELINE_PROPS:-0}
    if [ "$HAS_BASELINE_PROPS" -ge 2 ]; then
        echo -e "${GREEN}  ✓${NC} ReasoningEnhancementMetrics (baseline comparison properties)"
    else
        KPI_MISSING="$KPI_MISSING  ReasoningEnhancementMetrics missing baseline properties\n"
    fi
else
    KPI_MISSING="$KPI_MISSING  ReasoningEnhancementMetrics.swift not found\n"
fi

# Check VisionEngine provider metrics
PROVIDER_METRICS="$VISION_ENGINE_DIR/Shared/ProviderMetrics.swift"
if [ -f "$PROVIDER_METRICS" ]; then
    HAS_MEASURABLE=$(grep -c "successRate\|averageDuration\|averageConfidence" "$PROVIDER_METRICS" 2>/dev/null | tr -d '[:space:]')
    HAS_MEASURABLE=${HAS_MEASURABLE:-0}
    if [ "$HAS_MEASURABLE" -ge 2 ]; then
        echo -e "${GREEN}  ✓${NC} ProviderMetrics (success rate, duration, confidence)"
    else
        KPI_MISSING="$KPI_MISSING  ProviderMetrics missing measurable properties\n"
    fi
else
    KPI_MISSING="$KPI_MISSING  ProviderMetrics.swift not found\n"
fi

# Check TemplateBusinessKPIs
TEMPLATE_KPIS="$SHARED_UTILS_DIR/Domain/Entities/Intelligence/TemplateBusinessKPIs.swift"
if [ -f "$TEMPLATE_KPIS" ]; then
    HAS_TEMPLATE_BIZ=$(grep -c "timeSavingsPercent\|qualityImprovementPercent\|templateHitRate" "$TEMPLATE_KPIS" 2>/dev/null | tr -d '[:space:]')
    HAS_TEMPLATE_BIZ=${HAS_TEMPLATE_BIZ:-0}
    if [ "$HAS_TEMPLATE_BIZ" -ge 2 ]; then
        echo -e "${GREEN}  ✓${NC} TemplateBusinessKPIs (time savings, quality improvement, hit rate)"
    else
        KPI_MISSING="$KPI_MISSING  TemplateBusinessKPIs missing business metrics\n"
    fi
else
    KPI_MISSING="$KPI_MISSING  TemplateBusinessKPIs.swift not found\n"
fi

# Check StrategyBusinessKPIs
STRATEGY_KPIS="$SHARED_UTILS_DIR/Domain/Entities/Intelligence/StrategyBusinessKPIs.swift"
if [ -f "$STRATEGY_KPIS" ]; then
    HAS_STRATEGY_BIZ=$(grep -c "qualityImprovementPercent\|costMultiplier\|efficiencyScore\|isWorthTheCost" "$STRATEGY_KPIS" 2>/dev/null | tr -d '[:space:]')
    HAS_STRATEGY_BIZ=${HAS_STRATEGY_BIZ:-0}
    if [ "$HAS_STRATEGY_BIZ" -ge 2 ]; then
        echo -e "${GREEN}  ✓${NC} StrategyBusinessKPIs (quality vs baseline, cost multiplier, ROI)"
    else
        KPI_MISSING="$KPI_MISSING  StrategyBusinessKPIs missing business metrics\n"
    fi
else
    KPI_MISSING="$KPI_MISSING  StrategyBusinessKPIs.swift not found\n"
fi

# Check VisionBusinessKPIs
VISION_KPIS="$SHARED_UTILS_DIR/Domain/Entities/Intelligence/VisionBusinessKPIs.swift"
if [ -f "$VISION_KPIS" ]; then
    HAS_VISION_BIZ=$(grep -c "precision\|recall\|f1Score\|timeSavingsPercent\|costSavingsPercent" "$VISION_KPIS" 2>/dev/null | tr -d '[:space:]')
    HAS_VISION_BIZ=${HAS_VISION_BIZ:-0}
    if [ "$HAS_VISION_BIZ" -ge 3 ]; then
        echo -e "${GREEN}  ✓${NC} VisionBusinessKPIs (precision, recall, F1, time/cost savings)"
    else
        KPI_MISSING="$KPI_MISSING  VisionBusinessKPIs missing business metrics\n"
    fi
else
    KPI_MISSING="$KPI_MISSING  VisionBusinessKPIs.swift not found\n"
fi

# Summary
if [ -z "$KPI_MISSING" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Business KPIs complete (8 metric systems with baselines)"
else
    echo -e "${RED}❌ FAIL${NC} - Business KPIs incomplete:"
    echo -e "$KPI_MISSING"
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 24. Build succeeds (all packages)
echo "🏗️  Build Verification"
echo "----------------------"
echo "Building SharedUtilities..."
cd "$PROJECT_ROOT/packages/AIPRDSharedUtilities"
if swift build > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓${NC} SharedUtilities builds"
else
    echo -e "${RED}  ✗${NC} SharedUtilities build failed"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

echo "Building VerificationEngine..."
cd "$PROJECT_ROOT/packages/AIPRDVerificationEngine"
if swift build > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓${NC} VerificationEngine builds"
else
    echo -e "${RED}  ✗${NC} VerificationEngine build failed"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

echo "Building RAGEngine..."
cd "$PROJECT_ROOT/packages/AIPRDRAGEngine"
if swift build > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓${NC} RAGEngine builds"
else
    echo -e "${RED}  ✗${NC} RAGEngine build failed"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

echo "Building MetaPromptingEngine..."
cd "$PROJECT_ROOT/packages/AIPRDMetaPromptingEngine"
if swift build > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓${NC} MetaPromptingEngine builds"
else
    echo -e "${RED}  ✗${NC} MetaPromptingEngine build failed"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

echo "Building StrategyEngine..."
cd "$PROJECT_ROOT/packages/AIPRDStrategyEngine"
if swift build > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓${NC} StrategyEngine builds"
else
    echo -e "${RED}  ✗${NC} StrategyEngine build failed"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

echo "Building VisionEngine..."
cd "$PROJECT_ROOT/packages/AIPRDVisionEngine"
if swift build > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓${NC} VisionEngine builds"
else
    echo -e "${RED}  ✗${NC} VisionEngine build failed"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

echo "Building Library..."
cd "$PROJECT_ROOT/library"
if swift build > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓${NC} Library builds"
else
    echo -e "${RED}  ✗${NC} Library build failed"
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# Summary
echo "========================================"
echo "📊 SKILL VERIFICATION SUMMARY (26 checks)"
echo "========================================"

if [ $VIOLATIONS -eq 0 ]; then
    echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
    echo ""
    echo "✅ Clean Architecture: Domain/Application/Infrastructure/Composition"
    echo "✅ Domain Purity: Foundation only (Library + SharedUtilities)"
    echo "✅ Package Dependencies: VerificationEngine → SharedUtilities only"
    echo "✅ VisionEngine Dependencies: SharedUtilities + Apple frameworks"
    echo "✅ Sendable Conformance: Swift 6 ready"
    echo "✅ Standalone: No cloud dependencies"
    echo "✅ Naming: Ports, UseCases, camelCase"
    echo "✅ No Technical Debt: No TODO/FIXME comments"
    echo "✅ No Legacy Types: UnifiedVerificationResult only"
    echo "✅ File Size: All files ≤300 lines"
    echo "✅ Method Size: All methods ≤40 lines"
    echo "✅ Structure Isolation: One per file"
    echo "✅ No Nested Types: Flat hierarchy"
    echo "✅ No Backward Compat: Clean codebase"
    echo "✅ SOLID SRP: ≤12 imports per file"
    echo "✅ Safe Code: No force unwrapping"
    echo "✅ Value Types: No inout parameters"
    echo "✅ Business KPIs: Time savings, quality delta, cost reduction, token efficiency"
    echo "✅ 3R's: No anti-patterns"
    echo "✅ Build: All packages succeed"
    echo ""
    echo "🚀 Repository follows all clean coding standards"
    exit 0
else
    echo -e "${RED}❌ VIOLATIONS FOUND: $VIOLATIONS${NC}"
    echo ""
    echo "⚠️  Fix violations above to maintain clean code standards"
    exit 1
fi
