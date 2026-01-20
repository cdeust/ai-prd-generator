# AI PRD Generator - Prerequisites

**Complete setup guide for installing all required dependencies**

---

## Required Dependencies

### 1. Operating System

**Supported:**
- macOS 13+ (Ventura or later)
- Linux (Ubuntu 20.04+, Debian 11+, or equivalent)

**Verification:**
```bash
# macOS
sw_vers
# Expected: ProductVersion: 13.0 or higher

# Linux
lsb_release -a
# Expected: Ubuntu 20.04+ or Debian 11+
```

---

### 2. Swift 5.9+

**Why needed:** Skill is built with Swift Package Manager

#### Option A: Xcode (Recommended for macOS)

**Includes:** Swift compiler + all build tools + iOS/macOS SDKs

**Installation:**
1. Download from Mac App Store: https://apps.apple.com/app/xcode/id497799835
2. Open Xcode once to complete installation
3. Install command-line tools:
   ```bash
   xcode-select --install
   ```

**Verification:**
```bash
swift --version
# Expected: Apple Swift version 5.9 or higher
# Example: Apple Swift version 6.2.3 (swiftlang-6.2.3.3.21 clang-1700.6.3.2)
```

**Size:** ~15GB (Xcode) + ~2GB (command-line tools)

#### Option B: Swift Toolchain Only

**Use if:** You don't need Xcode's full IDE

**Installation:**
1. Download from https://swift.org/download/
2. Install the `.pkg` file
3. Add to PATH:
   ```bash
   export PATH="/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin:$PATH"
   ```

**Verification:**
```bash
swift --version
# Expected: Swift version 5.9 or higher
```

**Size:** ~2GB

---

### 3. Docker OR Colima

**Why needed:** Automatic PostgreSQL + pgvector setup for RAG (codebase analysis)

#### Option A: Docker Desktop (Standard)

**Pros:** Official, stable, GUI included
**Cons:** Requires license for commercial use, heavier weight

**Installation:**
1. Download: https://docs.docker.com/get-docker/
2. Install and start Docker Desktop
3. Verify:
   ```bash
   docker --version
   # Expected: Docker version 20.10 or higher

   docker ps
   # Should show empty container list (no errors)
   ```

**Size:** ~500MB

#### Option B: Colima + Docker CLI (Lightweight - Recommended)

**Pros:** Open source, lightweight, no license issues
**Cons:** Command-line only (no GUI)

**Installation:**
```bash
# Install Colima and Docker CLI
brew install colima docker

# Start Colima
colima start

# Verify
docker --version
# Expected: Docker version 20.10 or higher

docker ps
# Should show empty container list
```

**Start Colima on login (optional):**
```bash
# Add to ~/.zshrc or ~/.bash_profile
colima start
```

**Size:** ~200MB

---

### 4. Python 3.8+

**Why needed:** Wrapper scripts and utilities

**Installation:**
```bash
# macOS (usually pre-installed)
python3 --version
# If missing:
brew install python3

# Linux
sudo apt-get install python3 python3-pip
```

**Verification:**
```bash
python3 --version
# Expected: Python 3.8 or higher
```

---

### 5. AI Provider API Key

**Why needed:** Skill uses AI for PRD generation, clarification, verification

**Choose ONE:**

#### Option A: Anthropic Claude (Recommended)

**Why recommended:** Best for Chain of Verification (multi-LLM consensus)

**Get API key:**
1. Sign up: https://console.anthropic.com/
2. Create API key
3. Set environment variable:
   ```bash
   export ANTHROPIC_API_KEY="sk-ant-..."
   # Add to ~/.zshrc or ~/.bash_profile for persistence
   ```

**Pricing:** Pay-as-you-go (Claude Opus ~$15/million input tokens)

#### Option B: OpenAI GPT-4

**Get API key:**
1. Sign up: https://platform.openai.com/api-keys
2. Create API key
3. Set environment variable:
   ```bash
   export OPENAI_API_KEY="sk-..."
   ```

**Pricing:** Pay-as-you-go (GPT-4 ~$10/million input tokens)

#### Option C: Google Gemini

**Get API key:**
1. Sign up: https://ai.google.dev/
2. Create API key
3. Set environment variable:
   ```bash
   export GEMINI_API_KEY="..."
   ```

**Pricing:** Free tier available, pay-as-you-go

#### Option D: Apple Intelligence (No API Key)

**Requires:**
- macOS 26.0 Tahoe or later
- Apple Silicon (M1/M2/M3 or newer)
- No API key or internet connection needed

**Setup:**
```bash
# No setup required - works out of the box
# Skill automatically detects Apple Intelligence
```

**Pricing:** Free (local processing)

---

## Optional Dependencies

### 6. PostgreSQL 15+ with pgvector (Manual Setup)

**Only needed if:** You want to manage database manually instead of automatic Docker setup

**Not recommended:** Skill automatically starts PostgreSQL container with pgvector

**Manual installation (if really needed):**
```bash
# Install PostgreSQL and pgvector
brew install postgresql@15 pgvector

# Start PostgreSQL
brew services start postgresql@15

# Create database
createdb ai_prd

# Enable pgvector extension
psql ai_prd -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Set environment variable
export DATABASE_URL="postgresql://$(whoami)@localhost:5432/ai_prd"
```

---

## Quick Prerequisites Check Script

Run this to verify all dependencies:

```bash
#!/bin/bash

echo "=== AI PRD Generator - Prerequisites Check ==="
echo ""

# Check macOS version
echo "1. Operating System:"
if [[ "$OSTYPE" == "darwin"* ]]; then
    VERSION=$(sw_vers -productVersion)
    echo "   ✅ macOS $VERSION"
else
    echo "   ✅ Linux ($(lsb_release -d | cut -f2))"
fi
echo ""

# Check Swift
echo "2. Swift:"
if command -v swift &> /dev/null; then
    SWIFT_VERSION=$(swift --version | head -n 1)
    echo "   ✅ $SWIFT_VERSION"
else
    echo "   ❌ Swift not found - Install Xcode or Swift toolchain"
fi
echo ""

# Check Docker/Colima
echo "3. Docker/Colima:"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo "   ✅ $DOCKER_VERSION"
    if docker ps &> /dev/null; then
        echo "   ✅ Docker daemon running"
    else
        echo "   ⚠️  Docker daemon not running - Start Docker Desktop or 'colima start'"
    fi
else
    echo "   ❌ Docker not found - Install Docker Desktop or Colima"
fi
echo ""

# Check Python
echo "4. Python:"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "   ✅ $PYTHON_VERSION"
else
    echo "   ❌ Python 3 not found - Install with 'brew install python3'"
fi
echo ""

# Check API Keys
echo "5. AI Provider API Key:"
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "   ✅ Anthropic API key set"
elif [ -n "$OPENAI_API_KEY" ]; then
    echo "   ✅ OpenAI API key set"
elif [ -n "$GEMINI_API_KEY" ]; then
    echo "   ✅ Gemini API key set"
else
    echo "   ⚠️  No API key set - Set ANTHROPIC_API_KEY, OPENAI_API_KEY, or GEMINI_API_KEY"
    echo "      OR use Apple Intelligence (no key needed)"
fi
echo ""

echo "=== Summary ==="
echo "All required dependencies installed? → Proceed to installation"
echo "Missing something? → Install the missing prerequisites first"
```

**Save as:** `check-prerequisites.sh`

**Run:**
```bash
chmod +x check-prerequisites.sh
./check-prerequisites.sh
```

---

## Installation Order

Once all prerequisites are installed:

1. ✅ **Prerequisites** (this guide)
2. → **Installation** (See SKILL_INSTALLATION.md or README.md)
3. → **First Use** (Skill auto-compiles and sets up RAG database)

---

## Troubleshooting

### Swift compilation errors

**Problem:** `error: unable to find utility "xcrun"`

**Solution:**
```bash
xcode-select --install
```

### Docker permission denied

**Problem:** `permission denied while trying to connect to the Docker daemon socket`

**Solution (Docker Desktop):**
- Ensure Docker Desktop is running

**Solution (Colima):**
```bash
colima stop
colima start
```

### Python not found

**Problem:** `python3: command not found`

**Solution:**
```bash
brew install python3
```

### API key not recognized

**Problem:** Skill says "No API key found"

**Solution:**
```bash
# Add to shell config (~/.zshrc or ~/.bash_profile)
export ANTHROPIC_API_KEY="sk-ant-..."

# Reload shell
source ~/.zshrc
```

---

## Disk Space Requirements

**Total:** ~20GB

**Breakdown:**
- Xcode: ~15GB (or Swift toolchain: ~2GB)
- Docker Desktop: ~500MB (or Colima: ~200MB)
- PostgreSQL image (pgvector): ~200MB (automatic download)
- Skill package: ~1GB (library + dependencies)
- Embeddings storage: ~500MB per 100K LOC codebase

---

## Platform Support

| Platform | Supported | Notes |
|----------|-----------|-------|
| macOS 13+ (Intel) | ✅ | Fully supported |
| macOS 13-25 (Apple Silicon) | ✅ | Fully supported |
| macOS 26.0+ Tahoe (Apple Silicon) | ✅ | Fully supported + Apple Intelligence |
| macOS 12 or older | ❌ | Swift 5.9 not available |
| Ubuntu 20.04+ | ✅ | Fully supported |
| Debian 11+ | ✅ | Fully supported |
| Windows | ❌ | Swift on Windows is experimental |

---

## Next Steps

**Prerequisites complete?** → Proceed to installation:
- See [SKILL_INSTALLATION.md](./SKILL_INSTALLATION.md) for step-by-step guide
- See [README.md](./README.md) for quick installation

**Questions?** → Check troubleshooting section above or open an issue
