#!/bin/bash
# AI PRD Generator - First-time setup script

set -e

echo "🚀 AI PRD Generator - Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check Swift
if command -v swift &> /dev/null; then
    SWIFT_VERSION=$(swift --version | head -n 1)
    echo "✅ Swift found: $SWIFT_VERSION"
else
    echo "❌ Swift not found. Please install Swift 5.9+ from swift.org or install Xcode"
    exit 1
fi

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ Python found: $PYTHON_VERSION"
else
    echo "❌ Python 3.8+ not found. Please install Python"
    exit 1
fi

# Build Swift library
echo ""
echo "🔨 Building Swift library..."
cd library
swift build -c release
echo "✅ Library built successfully"

cd ..

# Check for API keys
echo ""
echo "🔑 Checking AI provider configuration..."

if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "✅ Anthropic API key configured"
elif [ -n "$OPENAI_API_KEY" ]; then
    echo "✅ OpenAI API key configured"
elif [ -n "$GEMINI_API_KEY" ]; then
    echo "✅ Gemini API key configured"
else
    echo "⚠️  No AI provider API key found"
    echo ""
    echo "Please set one of:"
    echo "  export ANTHROPIC_API_KEY='your-key'"
    echo "  export OPENAI_API_KEY='your-key'"
    echo "  export GEMINI_API_KEY='your-key'"
    echo ""
    echo "Or use Apple Intelligence (macOS 13+ only, no API key needed)"
fi

# Check for PostgreSQL (optional)
echo ""
echo "💾 Checking database configuration..."

if [ -n "$DATABASE_URL" ]; then
    echo "✅ PostgreSQL configured: $DATABASE_URL"
else
    echo "ℹ️  No PostgreSQL configured (using in-memory storage)"
    echo "   For persistent RAG, set: export DATABASE_URL='postgresql://localhost/ai_prd'"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Set your AI provider API key (see above)"
echo "2. Try: 'Generate a PRD for user authentication'"
echo "3. For codebase analysis, provide: 'Codebase: /path/to/your/project'"
echo "4. For mockup analysis, attach image files"
echo ""
