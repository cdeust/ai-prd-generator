# AI PRD Generator - Claude Code Skill

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B%20%7C%20Linux-lightgrey.svg)](https://github.com/cdeust/ai-prd-generator)
[![Standalone](https://img.shields.io/badge/Mode-Standalone-brightgreen.svg)](README.md)

> **✅ Completely Standalone - No Backend Required**
>
> This skill is 100% self-contained. Just add your AI API key and start generating PRDs.
> No databases, no backend services, no infrastructure setup needed.

## What This Skill Does

Generate professional Product Requirements Documents using state-of-the-art AI techniques:

✅ **Chain of Verification** - Multi-LLM consensus for quality assurance (production-proven)
✅ **Vision AI** - Analyze UI mockups and extract requirements (Anthropic, OpenAI, Gemini, Apple)
✅ **Iterative Clarification** - Ask questions until high confidence achieved
✅ **Test Case Generation** - Comprehensive test scenarios from requirements
✅ **OpenAPI Spec Generation** - API specifications for technical PRDs
✅ **100% Local** - Your data never leaves your machine
✅ **Optional RAG** - Add codebase analysis if you want it (not required)

## Prerequisites

### Required (Basic PRD Generation)

**IMPORTANT:** These are the ONLY requirements for basic PRD generation:

1. **macOS 13+** or **Linux**
   - macOS: Any version 13.0 (Ventura) or later
   - Linux: Ubuntu 20.04+, Debian 11+, or equivalent

2. **Swift 5.9+**
   - **Option A (Recommended)**: Install Xcode from App Store
     - Includes Swift compiler and all dependencies
     - Download: https://apps.apple.com/app/xcode/id497799835
   - **Option B**: Install Swift toolchain only
     - Lighter weight if you don't need Xcode
     - Download: https://swift.org/download/
   - Verify: `swift --version` (should show 5.9 or higher)

3. **AI Provider API Key** (choose one)
   - **Anthropic Claude** (Recommended): https://console.anthropic.com/
   - **OpenAI GPT-4**: https://platform.openai.com/api-keys
   - **Google Gemini**: https://ai.google.dev/
   - **Apple Intelligence**: No API key needed (requires macOS 26.0 Tahoe, built-in)

**That's it!** With just these three things, you can generate PRDs.

### Optional (Advanced RAG Features)

**Only install these if you want codebase analysis:**

4. **Docker OR Colima** (for automatic codebase indexing)
   - **Option A (Standard)**: Docker Desktop
     - Download: https://docs.docker.com/get-docker/
     - Verify: `docker --version`
   - **Option B (Lightweight)**: Colima + Docker CLI
     - Install: `brew install colima docker`
     - Start: `colima start`
     - Verify: `docker ps`
   - **Why needed**: Automatic PostgreSQL + pgvector setup for RAG
   - **Note**: pgvector is included in Docker image (no manual install)

5. **GitHub CLI** (for GitHub repository analysis)
   - Install: `brew install gh`
   - Authenticate: `gh auth login`
   - Verify: `gh auth status`
   - **Why needed**: Access private GitHub repositories for codebase analysis
   - **Note**: Uses official GitHub CLI for secure token management

**RAG = Retrieval Augmented Generation** - Analyzes your codebase to make PRDs context-aware of existing code patterns.

---

### Quick Prerequisites Check

```bash
# REQUIRED: Check Swift
swift --version
# Expected: Swift version 5.9+ or higher

# REQUIRED: Verify you have an API key
echo $ANTHROPIC_API_KEY
# Expected: sk-ant-... (or use OpenAI/Gemini/Apple instead)

# OPTIONAL: Check Docker (only for RAG)
docker --version
# Expected: Docker version 20.10+ or higher
# (Skip if you don't need codebase analysis)
```

**Required checks pass?** → Proceed to Installation

**Missing Swift?** → Install Xcode or Swift toolchain first

---

## Installation

### Quick Install

```bash
# 1. Extract the ZIP to Claude's skills directory
mkdir -p ~/.claude/skills
cd ~/.claude/skills
unzip /path/to/ai-prd-generator.zip

# 2. Run setup (one-time compilation)
cd ai-prd-generator
./scripts/setup.sh

# 3. Set API key (choose one)
export ANTHROPIC_API_KEY="sk-ant-..."
# OR
export OPENAI_API_KEY="sk-..."
# OR use Apple Intelligence (no key needed, macOS 26.0+)

# 4. Enable in Claude Code
claude-code skill add ai-prd-generator
```

### First Run

On first use, the skill will:
1. Compile the Swift library (~30 seconds one-time)
2. Initialize in-memory storage (no database needed)
3. Ready to generate PRDs!

**No backend services, no databases, no complex setup.**

---

## Usage Examples

### Basic PRD (Standalone Mode)

```
Generate a PRD for:
Title: "Real-time Chat System"
Description: "WebSocket-based chat with typing indicators, read receipts, and message history"
```

**Uses**: In-memory storage, AI API only
**No additional setup needed**

### With Mockup Analysis (Standalone)

```
Generate a PRD from this mockup:
[Attach dashboard-mockup.png]

Extract all UI components, interactions, and data requirements.
```

**Uses**: Vision AI (Claude/GPT-4V/Gemini/Apple), in-memory storage
**No additional setup needed**

### With Codebase Analysis (RAG Mode - Optional)

```
Generate a PRD for adding notifications to my app.

Codebase: /Users/me/my-react-app

Analyze:
- Existing WebSocket setup
- State management patterns
- API endpoint structure
```

**Uses**: RAG with PostgreSQL (Docker auto-starts on first use)
**Requires**: Docker installed (see Optional Prerequisites)

### GitHub Repository Analysis (RAG + GitHub CLI)

```
Generate a PRD for adding real-time notifications.

Repository: https://github.com/mycompany/webapp

Analyze:
- Existing architecture
- State management patterns
- API endpoints
```

**First time**: Run `gh auth login` to authenticate with GitHub CLI
**Subsequent uses**: Token automatically reused
**Requires**: GitHub CLI (`brew install gh`) + Docker for RAG indexing

---

## How It Works

### Standalone Mode (Default)

```
User Request
    ↓
Claude Code Skill
    ↓
Swift Library (In-Memory Storage)
    ↓
AI Provider API (Anthropic/OpenAI/Gemini/Apple)
    ↓
PRD Generated (Markdown)
```

**No databases, no backend, no external dependencies.**

### RAG Mode (Optional)

```
User Request + Codebase Path
    ↓
Claude Code Skill
    ↓
Docker Auto-Start (PostgreSQL + pgvector)
    ↓
Swift Library (Indexes codebase once)
    ↓
Hybrid Search (Vector + BM25)
    ↓
AI Provider API (with codebase context)
    ↓
Context-Aware PRD Generated
```

**Docker auto-starts on first RAG request - zero manual setup.**

---

## Features

### 1. Chain of Verification (Production-Proven Quality)

- **Multi-LLM consensus** - 3+ independent AI judges review PRD
- **Comprehensive validation** - Completeness, consistency, clarity, testability
- **Gap detection** - Identifies missing requirements all judges notice
- **Conflict resolution** - Finds contradictions between sections
- **Most reliable mechanism** - Proven quality assurance (not experimental)

### 2. Vision AI (Mockup Analysis)

- **Multi-provider support** - Claude, GPT-4V, Gemini, Apple Intelligence
- **Automatic fallback** - Switches providers if one fails
- **Component extraction** - Identifies buttons, forms, navigation, etc.
- **Interaction inference** - Understands user flows from UI
- **Data requirements** - Infers backend needs from UI
- **No manual annotation** - Just attach images

### 3. Iterative Clarification

- **Confidence scoring** - Only asks when needed (default 90% threshold)
- **Interactive questions** - Multi-choice UI for fast answers
- **Learning from answers** - Improves with each response
- **Focused on ambiguities** - Avoids obvious or low-value questions
- **Configurable rounds** - Default 5 max rounds

### 4. RAG (Optional Codebase Analysis)

- **Hybrid search** - Vector similarity + BM25 keyword search
- **Reciprocal Rank Fusion** - Combines rankings optimally
- **One-time indexing** - Reuses embeddings across PRD requests
- **Architecture-aware** - Respects your code patterns
- **Auto-containerized** - Docker handles database setup

### 5. GitHub Integration (Optional)

- **GitHub CLI Authentication** - Uses official `gh` CLI tool
- **Private repositories** - Full access with your GitHub account
- **Token storage** - Managed securely by GitHub CLI
- **One-time auth** - Run `gh auth login` once, token reused
- **Automatic RAG** - Indexes GitHub repos same as local code

---

## Configuration

Edit `skill-config.json` to customize:

```json
{
  "clarification": {
    "confidence_threshold": 0.90,  // 0.0-1.0 (higher = more questions)
    "max_rounds": 5,               // Max clarification iterations
    "min_questions_per_round": 2,
    "max_questions_per_round": 5
  },
  "rag": {
    "enabled": true,               // Auto-enable when codebase provided
    "chunk_size": 1000,
    "chunk_overlap": 200,
    "max_results": 10,
    "similarity_threshold": 0.7    // 0.0-1.0 (higher = stricter matching)
  },
  "vision": {
    "provider": "anthropic",       // anthropic, openai, gemini, apple
    "fallback_providers": ["openai", "gemini", "apple"],
    "max_retries": 3
  },
  "verification": {
    "enabled": true,               // Chain of Verification
    "num_judges": 3,               // Number of independent AI judges
    "consensus_threshold": 0.66    // 66% agreement required
  },
  "thinking": {
    "default_strategy": "chain-of-thought",
    "available_strategies": [
      "chain-of-thought",
      "tree-of-thought",
      "react"
    ]
  }
}
```

---

## Environment Variables

### Required (Choose One)

```bash
# Anthropic Claude (Recommended)
export ANTHROPIC_API_KEY="sk-ant-..."

# OR OpenAI GPT-4
export OPENAI_API_KEY="sk-..."

# OR Google Gemini
export GEMINI_API_KEY="..."

# OR Apple Intelligence (macOS 26.0+ only)
# No key needed - uses on-device models
```

### Optional (RAG Features)

```bash
# Use PostgreSQL for persistent codebase indexing
# (Defaults to in-memory if not set)
export DATABASE_URL="postgresql://localhost/ai_prd"

# Force storage type (auto-detected if not set)
export STORAGE_TYPE="postgres"  # or "memory"

# Confidence threshold override
export PRD_CONFIDENCE_THRESHOLD="0.95"

# Vision provider preference
export VISION_PROVIDER="anthropic"
```

---

## Generated PRD Structure

```markdown
# [Project Title]

**Confidence Score**: 0.92/1.00
**Generated**: 2026-01-20

## 1. Overview
- Summary
- Goals & Success Metrics
- Stakeholders

## 2. Requirements

### Functional Requirements
FR1: [Specific requirement]
...

### Non-Functional Requirements
NFR1: [Performance, security, etc.]
...

## 3. User Stories
US1: As a [role], I want [action] so that [benefit]
...

## 4. Technical Specification

### Architecture
[From codebase analysis if RAG enabled]

### API Endpoints
POST /api/endpoint - [Description]
[OpenAPI spec generated]

### Data Models
[Schema from mockup + codebase]

## 5. Test Cases
TC1: Given [context], when [action], then [result]
...

## 6. Acceptance Criteria
AC1: [Testable condition]
...

## Appendix

### A. Mockup Analysis Results
[Vision analysis output if images provided]

### B. Codebase Context
[RAG search results if codebase analyzed]

### C. Clarification Q&A
[Questions asked and answers received]

### D. Verification Results
[Chain of Verification scores and feedback]
```

---

## Performance

**Standalone Mode (In-Memory):**
- First run: 30s (compile library one-time)
- Subsequent runs: 2-5s startup
- PRD generation: 30-90s depending on complexity
- Mockup analysis: 3-5s per image
- No database overhead

**RAG Mode (With Codebase):**
- First run: 30s (compile) + 30s (Docker start)
- Codebase indexing: 1-2 min per 10K LOC (one-time)
- Subsequent runs: 2-5s startup (Docker stays running)
- PRD generation: 40-120s (includes RAG retrieval)
- Reuses embeddings (no re-indexing unless code changes)

---

## What's Included

```
ai-prd-generator/
├── SKILL.md                    # Skill instructions for Claude
├── README.md                   # This file
├── skill-config.json           # Configuration
├── library/                    # Full Swift library (self-contained)
│   ├── Package.swift
│   ├── Sources/
│   │   ├── Domain/            # Business entities (PRD, requirements, etc.)
│   │   ├── Application/       # Use cases (GeneratePRD, Clarification, etc.)
│   │   ├── Infrastructure/    # AI providers, RAG, Vision, InMemory repos
│   │   └── Composition/       # Dependency injection (LibraryComposition)
│   └── Tests/                 # Production validation tests
├── scripts/
│   ├── setup.sh               # First-time setup
│   └── docker-start.sh        # Auto-start Docker for RAG (optional)
├── examples/
│   ├── basic-prd.md           # Standalone example
│   ├── with-mockup.md         # Vision AI example
│   ├── with-codebase.md       # RAG example
│   └── with-github-repo.md    # GitHub integration example
└── GITHUB_INTEGRATION.md      # GitHub CLI integration guide
```

**Total size**: ~50MB (library + dependencies)
**Zero external services** - Everything runs locally

---

## Architecture

### Clean Architecture (Layered Isolation)

```
┌─────────────────────────────────────────┐
│   Claude Code Skill (SKILL.md)          │
│   • Interprets user requests            │
│   • Manages conversation flow           │
│   • Calls Swift library                 │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│   LibraryComposition (Public API)       │
│   • composition.useCases.generatePRD    │
│   • composition.useCases.clarification  │
│   • composition.useCases.verification   │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│   Application Layer (Use Cases)         │
│   • GeneratePRDUseCase                  │
│   • ClarificationOrchestratorUseCase    │
│   • ChainOfVerificationService          │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│   Domain Layer (Business Logic)         │
│   • PRDDocument, Requirements           │
│   • Entities, Value Objects             │
│   • Zero framework dependencies         │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│   Infrastructure Layer (Adapters)       │
│   • InMemory Repositories (default)     │
│   • AI Providers (Anthropic, OpenAI)    │
│   • Vision Analyzers (multi-provider)   │
│   • RAG System (optional PostgreSQL)    │
│   • GitHub CLI Integration              │
└─────────────────────────────────────────┘
```

**Key Design Principles:**
- **Dependency Inversion** - Business logic independent of frameworks
- **Interface Segregation** - Small, focused protocols
- **Single Responsibility** - Each component has one job
- **Zero Framework Dependencies** - Core logic uses only Foundation
- **InMemory by Default** - No database required for basic use

---

## Privacy & Security

✅ **100% local execution** - All processing on your machine
✅ **No data transmission** - PRDs stay local (except AI API calls for generation)
✅ **Codebase privacy** - Code never uploaded (only embeddings sent to AI for RAG)
✅ **InMemory storage** - No persistent data unless you enable PostgreSQL
✅ **API keys** - Environment variables only, never logged
✅ **GitHub tokens** - Stored encrypted in macOS Keychain
✅ **No telemetry** - Zero analytics, zero tracking

**AI Provider API Calls (Required for PRD generation):**
- Your requirements sent to AI provider (Anthropic/OpenAI/Gemini)
- PRD content generated by AI
- **Your codebase is NOT uploaded** - Only embeddings for RAG if enabled

**Apple Intelligence (On-Device Option):**
- Zero external API calls
- All processing on-device (macOS 26.0+)
- Maximum privacy

---

## Troubleshooting

### Skill Not Loading

**Problem**: Skill doesn't appear in Claude Code

**Solution**:
```bash
# Verify skill is in correct location
ls ~/.claude/skills/ai-prd-generator/SKILL.md

# Re-add skill
claude-code skill add ai-prd-generator

# Check Claude Code logs
tail -f ~/.claude/logs/claude-code.log
```

### Compilation Errors

**Problem**: Swift build fails

**Solution**:
```bash
# Verify Swift version
swift --version  # Should be 5.9+

# Clean and rebuild
cd ~/.claude/skills/ai-prd-generator/library
swift package clean
swift build
```

### API Key Not Found

**Problem**: "API key not found" error

**Solution**:
```bash
# Verify key is set
echo $ANTHROPIC_API_KEY  # Should print sk-ant-...

# Add to shell profile for persistence
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.zshrc
source ~/.zshrc
```

### RAG Not Working

**Problem**: Codebase analysis fails

**Solution**:
```bash
# Check Docker is running
docker ps

# Start Docker if not running
# macOS: Start Docker Desktop
# Linux: sudo systemctl start docker
# Colima: colima start

# Verify PostgreSQL container
docker ps | grep ai-prd-local-db

# Manual start if needed
cd ~/.claude/skills/ai-prd-generator
./scripts/docker-start.sh
```

### Vision Analysis Failed

**Problem**: Mockup analysis returns errors

**Solution**:
```bash
# Try different provider
export VISION_PROVIDER="openai"

# Check image format
file /path/to/mockup.png  # Should be PNG, JPG, or WEBP

# Verify API key for provider
echo $OPENAI_API_KEY
```

### GitHub Authentication Failed

**Problem**: Device flow code expired or authorization denied

**Solution**:
- Code expires in 15 minutes - request new one
- If denied, run again and click "Authorize" this time
- Check keychain if token exists: `security find-generic-password -s "ai-prd-generator"`
- Delete token to re-auth: `security delete-generic-password -s "ai-prd-generator" -a "github"`

---

## Frequently Asked Questions

### Do I need the full AI PRD backend?

**No.** This skill is completely standalone. The library includes in-memory repositories and works without any backend services.

### Do I need to install PostgreSQL?

**No.** PostgreSQL is only needed for optional RAG (codebase analysis) features. Docker auto-starts it when needed. For basic PRD generation, no database is required.

### Can I use this without Docker?

**Yes.** For basic PRD generation (no codebase analysis), you don't need Docker. Docker is only for RAG features.

### Which AI provider should I use?

**Anthropic Claude** (recommended) - Best for reasoning and structured output
**OpenAI GPT-4** - Great for creative requirements
**Apple Intelligence** - Best for privacy (on-device, macOS 26.0+)
**Google Gemini** - Good balance of speed and quality

### How much does it cost?

**Skill itself**: Free (MIT license)
**AI API costs** (varies by provider):
- Anthropic Claude: ~$0.50-$2 per PRD (depending on length)
- OpenAI GPT-4: ~$0.30-$1.50 per PRD
- Apple Intelligence: $0 (on-device, macOS 26.0+)

**RAG indexing** (one-time per codebase):
- Embedding costs: ~$0.10-$0.50 per 10K LOC (one-time)

### Can I use this for commercial projects?

**Yes.** MIT license allows commercial use. Generated PRDs are yours to use however you want.

### Does this work offline?

**Partially.** You need internet for:
- AI API calls (unless using Apple Intelligence)
- GitHub repository fetching
- Initial library compilation (downloads dependencies)

**Once compiled**, works offline if using Apple Intelligence.

### How do I update the skill?

```bash
# Download new version
cd ~/.claude/skills
rm -rf ai-prd-generator
unzip /path/to/ai-prd-generator-v2.0.0.zip

# Rebuild
cd ai-prd-generator
./scripts/setup.sh
```

---

## Contributing

This skill is self-contained and doesn't require the proprietary AI PRD backend repository. Contributions welcome for:

- Additional AI provider integrations
- Vision analyzer improvements
- New clarification strategies
- RAG performance optimizations
- Documentation improvements

**Architecture standards**: See `library/CLAUDE.md` for engineering principles

---

## License

MIT License - See [LICENSE](LICENSE) for details

---

## Support

- **Documentation**: See [SKILL.md](SKILL.md) for Claude instructions
- **Examples**: Check [examples/](examples/) folder for usage patterns
- **GitHub Integration**: See [GITHUB_INTEGRATION.md](GITHUB_INTEGRATION.md)
- **Issues**: Report at https://github.com/cdeust/ai-prd-generator/issues

---

**Ready to generate professional PRDs with AI!** 🚀

No backend, no complexity, just add your API key and go.
