# AI PRD Generator - Claude Code Skill

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey.svg)](https://github.com/cdeust/ai-prd-generator)
[![GitHub release](https://img.shields.io/github/v/release/cdeust/ai-prd-generator)](https://github.com/cdeust/ai-prd-generator/releases)

A comprehensive Claude Code skill that generates professional Product Requirements Documents using:
- **Chain of Verification** for multi-LLM quality assurance (most reliable mechanism)
- **RAG (Retrieval Augmented Generation)** for codebase analysis
- **Vision AI** for mockup interpretation
- **Iterative clarification** with confidence scoring

## What This Skill Does

This isn't just instructions - it's the complete AI PRD generation system running locally on your machine with:

✅ **Chain of Verification** (multi-LLM consensus validates quality - production-proven)
✅ **Full codebase analysis** using hybrid search (vector + BM25)
✅ **Multi-provider vision** (Claude, GPT-4V, Gemini, Apple Intelligence)
✅ **Confidence-based clarification** (asks questions until 90% confidence)
✅ **Test case generation** from requirements
✅ **OpenAPI spec generation** for APIs
✅ **Local execution** (your code never leaves your machine)

## Prerequisites

**IMPORTANT: Install these BEFORE running the skill setup:**

### Required (All Users)

1. **macOS 13+** or **Linux**
   - macOS: Ventura (13.0) or later
   - Linux: Ubuntu 20.04+, Debian 11+, or equivalent

2. **Swift 5.9+**
   - **Option A (Recommended)**: Install Xcode from App Store
     - Includes Swift compiler and all dependencies
     - Download: https://apps.apple.com/app/xcode/id497799835
   - **Option B**: Install Swift toolchain only
     - Lighter weight if you don't need Xcode
     - Download: https://swift.org/download/
   - Verify: `swift --version` (should show 5.9 or higher)

3. **Docker OR Colima** (for automatic RAG database)
   - **Option A (Standard)**: Docker Desktop
     - Download: https://docs.docker.com/get-docker/
     - Verify: `docker --version`
   - **Option B (Lightweight)**: Colima + Docker CLI
     - Install: `brew install colima docker`
     - Start: `colima start`
     - Verify: `docker ps`
   - **Why needed**: Automatic PostgreSQL + pgvector setup for codebase analysis
   - **Note**: pgvector is included in Docker image (no manual install)

4. **Python 3.8+**
   - Usually pre-installed on macOS
   - Verify: `python3 --version`
   - Install if missing: `brew install python3`

5. **AI Provider API Key** (choose one)
   - **Anthropic Claude** (Recommended): https://console.anthropic.com/
   - **OpenAI GPT-4**: https://platform.openai.com/api-keys
   - **Google Gemini**: https://ai.google.dev/
   - **Apple Intelligence**: No API key needed (macOS 13+, built-in)

### Optional (Advanced Features)

6. **PostgreSQL 15+** with **pgvector** (if NOT using Docker/Colima)
   - Only needed if you want to manage database manually
   - Skill auto-starts Docker container by default
   - Manual setup: `brew install postgresql@15 pgvector`

---

### Quick Prerequisites Check

Run these commands to verify your system is ready:

```bash
# Check Swift
swift --version
# Expected: Apple Swift version 5.9+ or higher

# Check Docker OR Colima
docker --version
# Expected: Docker version 20.10+ or higher

# Check Python
python3 --version
# Expected: Python 3.8+ or higher

# Check Claude Code (if already installed)
claude-code --version
# Expected: claude-code version X.Y.Z
```

**All checks pass?** → Proceed to Installation

**Missing something?** → Install the missing prerequisites first

---
## Installation

### Quick Install
```bash
# 1. Extract the ZIP to Claude's skills directory
mkdir -p ~/.claude/skills
cd ~/.claude/skills
unzip /path/to/ai-prd-generator.zip

# 2. Run setup
cd ai-prd-generator
./scripts/setup.sh

# 3. Set API key (choose one)
export ANTHROPIC_API_KEY="sk-ant-..."
# OR
export OPENAI_API_KEY="sk-..."
# OR use Apple Intelligence (no key needed, macOS 13+)

# 4. Enable in Claude Code
claude-code skill add ai-prd-generator
```

### First Run
On first use, the skill will:
1. Compile the Swift library (~30 seconds)
2. Initialize the configuration
3. Ready to generate PRDs!

## Usage Examples

### Basic PRD
```
Generate a PRD for:
Title: "Real-time Chat System"
Description: "WebSocket-based chat with typing indicators, read receipts, and message history"
```

### With Mockup Analysis
```
Generate a PRD from this mockup:
[Attach dashboard-mockup.png]

Extract all UI components, interactions, and data requirements.
```

### With Codebase Analysis
```
Generate a PRD for adding notifications to my app.

Codebase: /Users/me/my-react-app

Analyze:
- Existing WebSocket setup
- State management patterns
- API endpoint structure
```

### Full System (Everything)
```
Generate a PRD for this checkout flow:
[Attach checkout-mobile.png, checkout-desktop.png]

Codebase: /Users/me/ecommerce-app

Use RAG to find:
- Current Stripe integration
- Payment error handling
- Cart management patterns

Generate with 95% confidence threshold.
```

## Features

### 1. Chain of Verification (Production-Proven Quality)
- **Multi-LLM consensus** - 3+ independent AI judges review PRD
- **Comprehensive validation** - Completeness, consistency, clarity, testability
- **Gap detection** - Identifies missing requirements all judges notice
- **Conflict resolution** - Finds contradictions between sections
- **Most reliable mechanism** - Proven quality assurance (not experimental)

### 2. Codebase RAG
- Indexes your code once, reuses embeddings
- Hybrid search (vector + full-text)
- Finds relevant patterns automatically
- Respects your architecture

### 3. Mockup Vision
- Extracts UI components
- Infers interactions
- Identifies data requirements
- Suggests technical implementation

### 4. Smart Clarification
- Only asks high-value questions
- Iterates until confidence threshold met
- Learns from your answers
- Focuses on ambiguities

## Configuration

Edit `skill-config.json` to customize:

```json
{
  "clarification": {
    "confidence_threshold": 0.90,  // 0.0-1.0
    "max_rounds": 5
  },
  "rag": {
    "enabled": true,
    "max_results": 10,
    "similarity_threshold": 0.7
  },
  "vision": {
    "provider": "anthropic",  // anthropic, openai, gemini, apple
    "fallback_providers": ["openai", "gemini"]
  },
  "verification": {
    "enabled": true,
    "num_judges": 3,
    "consensus_threshold": 0.66
  }
}
```

## Environment Variables

```bash
# Required: AI Provider (choose one)
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export GEMINI_API_KEY="..."
# Or use Apple Intelligence (macOS 13+ only)

# Optional: PostgreSQL for persistent RAG
export DATABASE_URL="postgresql://localhost/ai_prd"
export STORAGE_TYPE="postgres"  # or "memory"

# Optional: Confidence threshold override
export PRD_CONFIDENCE_THRESHOLD="0.95"

# Optional: Vision provider preference
export VISION_PROVIDER="anthropic"
```

## Output Structure

Generated PRDs include:

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
[From codebase analysis if provided]

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
[Vision analysis output]

### B. Codebase Context
[RAG search results]

### C. Clarification Q&A
[Questions asked and answers received]

### D. Verification Results
[Chain of Verification scores]
```

## Performance

- **First run**: 30-60s (compile library)
- **Subsequent runs**: 2-5s startup
- **Codebase indexing**: 1-2 min per 10K LOC (one-time)
- **Mockup analysis**: 3-5s per image
- **PRD generation**: 30-120s depending on complexity

## Requirements

- **macOS 13+** or **Linux**
- **Swift 5.9+** (Xcode or swift.org)
- **Python 3.8+**
- **AI Provider API key** (Anthropic/OpenAI/Gemini) or Apple Intelligence
- **PostgreSQL** (optional, for persistent RAG)
- **Disk space**: ~500MB for library + embeddings

## Privacy & Security

✅ **100% local execution** - Code runs on your machine
✅ **No data transmission** - PRDs stay local
✅ **Codebase privacy** - Never uploaded anywhere
✅ **Local embeddings** - Stored on your disk only
✅ **API keys** - Environment variables only, never logged

## Troubleshooting

**Compilation errors:**
```bash
cd library && swift build
```

**API key not found:**
```bash
echo $ANTHROPIC_API_KEY  # Should print your key
```

**Codebase indexing slow:**
```bash
# Use memory storage for faster (but non-persistent) indexing
export STORAGE_TYPE="memory"
```

**Mockup analysis failed:**
```bash
# Try different provider
export VISION_PROVIDER="openai"
```

## What's Included

```
ai-prd-generator/
├── SKILL.md                    # Skill instructions for Claude
├── README.md                   # This file
├── skill-config.json           # Configuration
├── library/                    # Full Swift library (1060 files)
│   ├── Package.swift
│   ├── Sources/
│   │   ├── Domain/            # Business entities
│   │   ├── Application/       # Use cases & services
│   │   ├── Infrastructure/    # AI providers, RAG, vision
│   │   └── Composition/       # Dependency injection
│   └── Tests/
├── scripts/
│   └── setup.sh               # First-time setup
└── examples/
    ├── basic-prd.md           # Example outputs
    ├── with-mockup.md
    └── with-codebase.md
```

## Support

- **Documentation**: See library/README.md for API details
- **Examples**: Check examples/ folder
- **Issues**: Report bugs or request features

## License

MIT

---

**Ready to generate professional PRDs with AI!** 🚀
