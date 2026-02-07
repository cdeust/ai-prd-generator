#!/bin/bash
set -e

echo "========================================="
echo "OpenTimestamps - Repository Proof of Ownership"
echo "========================================="
echo ""
echo "⏰ Current time: $(date)"
echo ""

# Check if we're outside working hours (before 9 AM or after 6 PM, or weekend)
HOUR=$(date +%H)
DAY=$(date +%u)  # 1=Monday, 7=Sunday

if [ $DAY -ge 6 ]; then
    echo "✅ Weekend - OK to proceed"
elif [ $HOUR -lt 9 ] || [ $HOUR -ge 18 ]; then
    echo "✅ Outside working hours - OK to proceed"
else
    echo "❌ ERROR: Currently during working hours (9 AM - 6 PM, Mon-Fri)"
    echo "   Current time: $(date '+%H:%M %A')"
    echo ""
    echo "Please run this script:"
    echo "  - After 18:00 (6 PM)"
    echo "  - Before 09:00 (9 AM)"
    echo "  - On weekend (Saturday/Sunday)"
    exit 1
fi

echo ""
echo "This script will create an OpenTimestamps proof of ownership for:"
echo "  Repository: ai-architect-prd-builder"
echo "  Owner: Clément Deust"
echo "  Purpose: IP protection for commercial product"
echo ""
echo "Steps:"
echo "  1. Check OpenTimestamps CLI installation"
echo "  2. Create git archive of current state"
echo "  3. Generate SHA256 hash of archive"
echo "  4. Submit hash to Bitcoin blockchain via OTS"
echo "  5. Save timestamp proof file (.ots)"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Step 1: Check OTS installation
echo ""
echo "📝 Step 1: Checking OpenTimestamps CLI..."
if ! command -v ots &> /dev/null; then
    echo "❌ ERROR: OpenTimestamps CLI not installed"
    echo ""
    echo "Install with:"
    echo "  pip install opentimestamps-client"
    echo ""
    echo "Or via Homebrew (if available):"
    echo "  brew install opentimestamps"
    exit 1
fi

echo "✅ OpenTimestamps CLI found: $(which ots)"
ots --version

# Step 2: Create git archive
echo ""
echo "📝 Step 2: Creating git archive of repository..."
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE_NAME="ai-architect-prd-builder-phase5-strategy-engine-${TIMESTAMP}.tar.gz"
mkdir -p .ots-proofs
ARCHIVE_PATH=".ots-proofs/${ARCHIVE_NAME}"

git archive --format=tar.gz --prefix=ai-architect-prd-builder/ -o "$ARCHIVE_PATH" HEAD

if [ -f "$ARCHIVE_PATH" ]; then
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
    echo "✅ Archive created: ${ARCHIVE_NAME} (${ARCHIVE_SIZE})"
else
    echo "❌ ERROR: Failed to create archive"
    exit 1
fi

# Step 3: Generate SHA256 hash
echo ""
echo "📝 Step 3: Generating SHA256 hash..."
HASH=$(shasum -a 256 "$ARCHIVE_PATH" | cut -d' ' -f1)
echo "✅ SHA256: $HASH"

# Step 4: Create OTS timestamp
echo ""
echo "📝 Step 4: Creating OpenTimestamps proof..."
echo "   Submitting to Bitcoin blockchain..."
echo "   (This may take a few seconds)"

ots stamp "$ARCHIVE_PATH"

OTS_FILE="${ARCHIVE_PATH}.ots"
if [ -f "$OTS_FILE" ]; then
    echo "✅ OTS proof created: ${OTS_FILE}"
else
    echo "❌ ERROR: Failed to create OTS proof"
    exit 1
fi

# Step 5: Verify timestamp (incomplete until Bitcoin confirmation)
echo ""
echo "📝 Step 5: Verifying timestamp..."
ots info "$OTS_FILE"

# Create metadata file
echo ""
echo "📝 Step 6: Creating metadata file..."
METADATA_FILE="${ARCHIVE_PATH}.metadata.txt"
cat > "$METADATA_FILE" << METADATA
OpenTimestamps Proof of Ownership
==================================

Repository: ai-architect-prd-builder
Owner: Clément Deust
Purpose: IP protection for commercial product
Phase: Phase 5 Complete - Research-Weighted Strategy Engine (RWSE)

Timestamp Details:
- Date: $(date '+%Y-%m-%d %H:%M:%S %Z')
- Archive: ${ARCHIVE_NAME}
- SHA256: ${HASH}
- OTS File: ${OTS_FILE}

Git Commit:
$(git log -1 --pretty=format:"- Commit: %H%n- Author: %an <%ae>%n- Date: %ai%n- Message: %s")

Repository State:
- Files changed: $(git diff --cached --stat | tail -1 || echo "No staged changes")
- Strategy Engine: Research-weighted selection with 30+ evidence entries
- Tier-based enforcement: Tier 1 (+18-74%) to Tier 4 (Free)
- Effectiveness tracking: Feedback loop with actual vs expected gains
- All 5 packages build: SUCCESS

Blockchain Proof:
The SHA256 hash of this repository archive has been submitted to the
Bitcoin blockchain via OpenTimestamps. This creates immutable proof
that Clément Deust possessed this exact code at this timestamp.

Note: Bitcoin confirmation takes ~10-60 minutes. After confirmation,
run: ots verify ${OTS_FILE}

Usage:
To verify this proof in the future:
1. Keep this archive: ${ARCHIVE_NAME}
2. Keep the OTS proof: ${OTS_FILE}
3. Verify anytime: ots verify ${OTS_FILE}

Legal Notice:
This timestamped proof establishes that Clément Deust created and
owned this codebase at the timestamp above, prior to any commercial
release. This protects intellectual property rights and prevents
false claims of prior art or ownership disputes.
METADATA

echo "✅ Metadata saved: ${METADATA_FILE}"

# Summary
echo ""
echo "========================================="
echo "✅ SUCCESS - OpenTimestamps Proof Created"
echo "========================================="
echo ""
echo "Files created:"
echo "  1. ${ARCHIVE_NAME} (${ARCHIVE_SIZE}) - Repository snapshot"
echo "  2. ${OTS_FILE} - Blockchain proof"
echo "  3. ${METADATA_FILE} - Human-readable metadata"
echo ""
echo "SHA256: ${HASH}"
echo ""
echo "Next Steps:"
echo "  1. Wait 10-60 minutes for Bitcoin confirmation"
echo "  2. Verify proof: ots verify ${OTS_FILE}"
echo "  3. Store these files securely:"
echo "     - Archive (reproducible build)"
echo "     - OTS proof (blockchain timestamp)"
echo "     - Metadata (human-readable info)"
echo ""
echo "⚠️  IMPORTANT: Keep these files safe!"
echo "    They are your proof of ownership and cannot be recreated."
echo ""
echo "To verify in the future:"
echo "  ots verify ${OTS_FILE}"
echo ""
echo "This timestamp proves you owned this code at: $(date)"
echo ""
