#!/bin/bash

# Incremental Migration Script: Move files to SharedUtilities
# Usage: ./migrate-to-shared.sh <batch-number>

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIBRARY_SRC="$PROJECT_ROOT/library/Sources"
SHARED_SRC="$PROJECT_ROOT/packages/AIPRDSharedUtilities/Sources"

echo "🔄 Migrating files to SharedUtilities..."
echo "Project root: $PROJECT_ROOT"

BATCH=${1:-1}

case $BATCH in
    1)
        echo "📦 Batch 1: Core Configuration Types"
        # ThinkingMode
        cp "$LIBRARY_SRC/Domain/Entities/Configuration/ThinkingMode.swift" \
           "$SHARED_SRC/Domain/ValueObjects/ThinkingMode.swift"

        # PrivacyLevel
        cp "$LIBRARY_SRC/Domain/Entities/Configuration/PrivacyLevel.swift" \
           "$SHARED_SRC/Domain/ValueObjects/PrivacyLevel.swift"

        # PRDStatus
        cp "$LIBRARY_SRC/Domain/ValueObjects/PRDStatus.swift" \
           "$SHARED_SRC/Domain/ValueObjects/PRDStatus.swift"

        # PRDPrivacyLevel
        cp "$LIBRARY_SRC/Domain/ValueObjects/PRDPrivacyLevel.swift" \
           "$SHARED_SRC/Domain/ValueObjects/PRDPrivacyLevel.swift"

        echo "✅ Batch 1 complete"
        ;;

    2)
        echo "📦 Batch 2: Chat and Message Types"
        cp "$LIBRARY_SRC/Domain/ValueObjects/ChatMessage.swift" \
           "$SHARED_SRC/Domain/ValueObjects/ChatMessage.swift"
        echo "✅ Batch 2 complete"
        ;;

    3)
        echo "📦 Batch 3: Core Error Types"
        mkdir -p "$SHARED_SRC/Domain/ValueObjects/Errors"

        for file in AIProviderError ChunkingError RepositoryError; do
            cp "$LIBRARY_SRC/Domain/ValueObjects/Errors/${file}.swift" \
               "$SHARED_SRC/Domain/ValueObjects/Errors/${file}.swift"
        done
        echo "✅ Batch 3 complete"
        ;;

    *)
        echo "❌ Invalid batch number: $BATCH"
        echo "Valid batches: 1-3"
        exit 1
        ;;
esac

# Build SharedUtilities to verify
echo ""
echo "🏗️  Building SharedUtilities..."
cd "$PROJECT_ROOT/packages/AIPRDSharedUtilities"
if swift build; then
    echo "✅ SharedUtilities builds successfully"
else
    echo "❌ SharedUtilities build failed"
    exit 1
fi

echo ""
echo "🎉 Batch $BATCH migration complete!"
