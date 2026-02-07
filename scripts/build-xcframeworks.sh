#!/bin/bash
# build-xcframeworks.sh — Build all 8 engine packages as XCFrameworks
# Usage: ./scripts/build-xcframeworks.sh
#
# SPM packages produce relocatable .o objects (not .framework bundles) when archived.
# This script:
#   1. Archives each engine with xcodebuild (BUILD_LIBRARY_FOR_DISTRIBUTION=YES)
#   2. Wraps the .o into a static library with libtool
#   3. Copies the .swiftmodule from DerivedData
#   4. Creates .xcframework using -library + -headers (swiftmodule)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build"
ARCHIVES_DIR="$BUILD_DIR/archives"
XCFRAMEWORKS_DIR="$BUILD_DIR/xcframeworks"
STAGING_DIR="$BUILD_DIR/staging"
PACKAGES_DIR="$REPO_ROOT/packages"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"

# Build order respecting dependencies
ENGINES=(
    "AIPRDSharedUtilities"      # Layer 0: No deps
    "AIPRDRAGEngine"            # Layer 1: SharedUtilities
    "AIPRDVerificationEngine"   # Layer 1: SharedUtilities
    "AIPRDMetaPromptingEngine"  # Layer 1: SharedUtilities
    "AIPRDStrategyEngine"       # Layer 1: SharedUtilities
    "AIPRDEncryptionEngine"     # Layer 1: SharedUtilities
    "AIPRDVisionEngine"         # Layer 1: SharedUtilities (may fail: @Generable macro)
    "AIPRDOrchestrationEngine"  # Layer 2: SharedUtilities + others
)

echo "═══════════════════════════════════════════════════════"
echo "  AIPRD XCFramework Builder"
echo "  Building ${#ENGINES[@]} engines for macOS (arm64 + x86_64)"
echo "═══════════════════════════════════════════════════════"
echo ""

# Clean build directories (but preserve spm-cache for incremental builds)
rm -rf "$ARCHIVES_DIR" "$XCFRAMEWORKS_DIR" "$STAGING_DIR"
mkdir -p "$ARCHIVES_DIR" "$XCFRAMEWORKS_DIR" "$STAGING_DIR"

SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_ENGINES=()

for ENGINE in "${ENGINES[@]}"; do
    PACKAGE_DIR="$PACKAGES_DIR/$ENGINE"
    ARCHIVE_PATH="$ARCHIVES_DIR/${ENGINE}-macos.xcarchive"
    XCFRAMEWORK_PATH="$XCFRAMEWORKS_DIR/${ENGINE}.xcframework"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Building: $ENGINE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ ! -d "$PACKAGE_DIR" ]; then
        echo "  ❌ Package directory not found: $PACKAGE_DIR"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_ENGINES+=("$ENGINE (not found)")
        continue
    fi

    # Step 1: Archive with xcodebuild
    echo "  → xcodebuild archive..."
    if xcodebuild archive \
        -workspace "$PACKAGE_DIR" \
        -scheme "$ENGINE" \
        -destination "generic/platform=macOS" \
        -archivePath "$ARCHIVE_PATH" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO \
        OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface" \
        2>"$BUILD_DIR/${ENGINE}-archive.log"; then
        echo "  ✅ Archive succeeded"
    else
        echo "  ❌ Archive failed for $ENGINE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_ENGINES+=("$ENGINE (archive failed)")
        continue
    fi

    # Step 2: Find the .o file in the archive
    OBJ_FILE=$(find "$ARCHIVE_PATH/Products" -name "${ENGINE}.o" -type f 2>/dev/null | head -1)
    if [ -z "$OBJ_FILE" ]; then
        echo "  ❌ No .o file found in archive for $ENGINE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_ENGINES+=("$ENGINE (no .o in archive)")
        continue
    fi
    echo "  → Found object: $(basename "$OBJ_FILE") ($(du -h "$OBJ_FILE" | cut -f1))"

    # Step 3: Create static library from .o using libtool
    STAGE_DIR="$STAGING_DIR/$ENGINE"
    mkdir -p "$STAGE_DIR"
    STATIC_LIB="$STAGE_DIR/lib${ENGINE}.a"

    libtool -static -o "$STATIC_LIB" "$OBJ_FILE" 2>/dev/null
    echo "  ✅ Static library created: $(du -h "$STATIC_LIB" | cut -f1)"

    # Step 4: Find .swiftmodule from DerivedData (has .swiftinterface files)
    DD_DIR=$(find "$DERIVED_DATA" -maxdepth 1 -name "${ENGINE}-*" -type d 2>/dev/null | head -1)
    SWIFT_MODULE_DIR=""
    if [ -n "$DD_DIR" ]; then
        SWIFT_MODULE_DIR=$(find "$DD_DIR" -path "*ArchiveIntermediates*BuildProductsPath/Release/${ENGINE}.swiftmodule" -type d 2>/dev/null | head -1)
    fi

    if [ -z "$SWIFT_MODULE_DIR" ]; then
        echo "  ⚠️  No .swiftmodule in DerivedData, trying archive..."
        SWIFT_MODULE_DIR=$(find "$ARCHIVE_PATH" -name "${ENGINE}.swiftmodule" -type d 2>/dev/null | head -1)
    fi

    STAGED_MODULE=""
    if [ -n "$SWIFT_MODULE_DIR" ] && [ -d "$SWIFT_MODULE_DIR" ]; then
        # Copy swiftmodule to staging for clean reference
        STAGED_MODULE="$STAGE_DIR/${ENGINE}.swiftmodule"
        cp -R "$SWIFT_MODULE_DIR" "$STAGED_MODULE"
        echo "  ✅ Swift module found: $(ls "$STAGED_MODULE" | wc -l | tr -d ' ') files"
    else
        echo "  ⚠️  No Swift module found (xcframework will lack interface)"
    fi

    # Step 5: Create XCFramework
    echo "  → xcodebuild -create-xcframework..."
    rm -rf "$XCFRAMEWORK_PATH"
    if [ -n "$STAGED_MODULE" ]; then
        CREATE_RESULT=$(xcodebuild -create-xcframework \
            -library "$STATIC_LIB" \
            -headers "$STAGED_MODULE" \
            -output "$XCFRAMEWORK_PATH" \
            2>"$BUILD_DIR/${ENGINE}-xcframework.log" && echo "OK" || echo "FAIL")
    else
        CREATE_RESULT=$(xcodebuild -create-xcframework \
            -library "$STATIC_LIB" \
            -output "$XCFRAMEWORK_PATH" \
            2>"$BUILD_DIR/${ENGINE}-xcframework.log" && echo "OK" || echo "FAIL")
    fi
    if [ "$CREATE_RESULT" = "OK" ]; then
        SIZE=$(du -sh "$XCFRAMEWORK_PATH" | cut -f1)
        echo "  ✅ XCFramework created: $SIZE"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ❌ Failed to create XCFramework"
        cat "$BUILD_DIR/${ENGINE}-xcframework.log" | tail -5
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_ENGINES+=("$ENGINE (xcframework creation)")
    fi

    echo ""
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Build Summary"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  ✅ Succeeded: $SUCCESS_COUNT / ${#ENGINES[@]}"
echo "  ❌ Failed:    $FAIL_COUNT / ${#ENGINES[@]}"
if [ ${#FAILED_ENGINES[@]} -gt 0 ]; then
    echo ""
    echo "  Failed engines:"
    for FAILED in "${FAILED_ENGINES[@]}"; do
        echo "    - $FAILED"
    done
fi
echo ""
echo "  XCFrameworks:"
for xcf in "$XCFRAMEWORKS_DIR"/*.xcframework; do
    if [ -d "$xcf" ]; then
        NAME=$(basename "$xcf")
        SIZE=$(du -sh "$xcf" | cut -f1)
        echo "    $NAME ($SIZE)"
    fi
done
echo ""
echo "  Build logs: $BUILD_DIR/"
echo "═══════════════════════════════════════════════════════"
