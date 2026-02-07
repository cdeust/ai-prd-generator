# AI PRD Generator

[![License: Commercial](https://img.shields.io/badge/License-Commercial-green.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-lightgrey.svg)](README.md)
[![Version](https://img.shields.io/badge/Version-1.0.0--mvp-blue.svg)](CHANGELOG.md)

> **Licensed Software** - Requires a valid license for full functionality.
> Free tier available with basic features.

## What This Does

Generate professional Product Requirements Documents powered by 8 specialized AI engines:

### 8 Engine Architecture

| Engine | Purpose | Key Capability |
|--------|---------|----------------|
| **SharedUtilities** | Domain types, 42 ports, value objects | Foundation layer |
| **RAGEngine** | Contextual BM25, hybrid search | +49% precision over standard RAG |
| **VerificationEngine** | 6 strategies, plugin architecture | Multi-LLM consensus |
| **MetaPromptingEngine** | 15 strategies, enhancements | Research-backed (MIT, Stanford, Harvard) |
| **StrategyEngine** | Research-weighted enforcement | Tier 1-4 selection |
| **VisionEngine** | Apple Foundation Models | 180+ components, on-device inference |
| **OrchestrationEngine** | PRD pipeline, JIRA export | End-to-end generation |
| **EncryptionEngine** | PII detection, license validation | Hardware-bound distribution |

### 8 Context-Aware PRD Types

| PRD Type | Sections | Questions | RAG Depth | Focus |
|----------|----------|-----------|-----------|-------|
| **proposal** | 7 | 5-6 | 1 hop | Business value, ROI |
| **feature** | 11 | 8-10 | 3 hops | Technical depth |
| **bug** | 6 | 6-8 | 3 hops | Root cause analysis |
| **incident** | 8 | 10-12 | 4 hops | Forensic investigation |
| **poc** | 5 | 4-5 | 2 hops | Feasibility validation |
| **mvp** | 8 | 6-7 | 2 hops | Core value focus |
| **release** | 10 | 9-11 | 3 hops | Production readiness |
| **cicd** | 9 | 7-9 | 3 hops | Pipeline automation |

### Key Features

- **15 Thinking Strategies** - Research-backed (MIT, Stanford, Harvard, Anthropic, OpenAI, DeepSeek)
- **Chain of Verification** - Multi-LLM consensus with 6 innovative algorithms
- **Contextual BM25 RAG** - +49% precision improvement over standard RAG
- **Business KPIs** - 8 metric systems with documented baselines
- **Strategy Engine** - Research-weighted selection with effectiveness tracking
- **Vision Engine** - Apple Foundation Models (macOS 26+), 180+ cross-platform components
- **Hardware-Bound Licensing** - Ed25519 signed, encrypted XCFramework distribution
- **100% Local** - Your data never leaves your machine

---

## Prerequisites

### Required

1. **macOS 14+** (macOS 26+ for Vision Engine with Apple Foundation Models)
2. **Swift 6.2+** - Install via Xcode or Swift toolchain
3. **AI Provider API Key** - Anthropic (recommended), OpenAI, Gemini, or Apple Intelligence
4. **Valid License** - For full feature access (free tier available)

### Optional (for RAG)

5. **Docker** or **Colima** - For codebase indexing
6. **GitHub CLI** - For private repository analysis

---

## Installation

```bash
# 1. Clone to Claude's skills directory
mkdir -p ~/.claude/skills
cd ~/.claude/skills
git clone https://github.com/cdeust/ai-prd-generator.git

# 2. Run setup
cd ai-prd-generator
./scripts/setup.sh

# 3. Set API key
export ANTHROPIC_API_KEY="sk-ant-..."
```

---

## License Tiers

| Feature | Free | Licensed |
|---------|------|----------|
| Thinking Strategies | Zero-Shot, CoT | All 15 strategies |
| RAG | Basic keyword search | Hybrid + Contextual BM25 |
| Verification | Basic LLM check | Full pipeline (6 algorithms) |
| Strategy Engine | Basic selection | Research-weighted enforcement |
| PRD Types | feature, bug | All 8 types |
| Vision Engine | - | 180+ components |

---

## Encrypted Distribution

Licensed engines are distributed as encrypted XCFrameworks:

- **AES-256-GCM** encryption with HKDF key derivation
- **Hardware-bound** - tied to specific machine fingerprint
- **Ed25519 signed** licenses with cryptographic verification
- **AIPRD-ENC-V1** format with integrity validation

```bash
# Build XCFrameworks
./scripts/build-xcframeworks.sh

# Encrypt for distribution
swiftc -o /tmp/encrypt-frameworks scripts/encrypt-frameworks.swift -framework IOKit
/tmp/encrypt-frameworks

# Test the pipeline
swiftc -o /tmp/test-encryption scripts/test-encryption.swift -framework IOKit
/tmp/test-encryption
```

---

## Usage Examples

### Basic PRD

```
Generate a PRD for:
Title: "Real-time Chat System"
Description: "WebSocket-based chat with typing indicators"
```

### With Context Type

```
Generate a RELEASE PRD for:
Title: "v2.0 Production Deployment"
Description: "Major version upgrade with breaking API changes"
```

### With Codebase Analysis

```
Generate a FEATURE PRD for adding notifications.
Codebase: /Users/me/my-react-app
```

### With Mockup Analysis

```
Generate a PRD for this mockup: [attach image]
Title: "Dashboard Redesign"
```

---

## Privacy & Security

- **100% local execution** - All processing on your machine
- **No telemetry** - Zero analytics, zero tracking
- **Codebase privacy** - Code never uploaded (only local embeddings for RAG)
- **API keys** - Environment variables only, never logged
- **Hardware-bound licensing** - Licenses tied to specific machines

---

## Documentation

- **Full Documentation**: See [SKILL.md](SKILL.md)
- **Changelog**: See [CHANGELOG.md](CHANGELOG.md)
- **Examples**: Check [examples/](examples/)

---

## License

**Commercial License** - See [LICENSE](LICENSE)

This software requires a valid license for full functionality. A free tier with basic features is available without a license.

---

**© 2026 Clement Deust** - All rights reserved.
