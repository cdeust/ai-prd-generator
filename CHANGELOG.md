# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-20

### Added
- **Chain of Verification** - Multi-LLM consensus quality assurance (3+ AI judges)
- **RAG Codebase Analysis** - Hybrid search combining vector similarity (pgvector) and BM25 full-text search
- **Vision Mockup Analysis** - Support for 4 providers (Claude, GPT-4V, Gemini, Apple Intelligence)
- **Iterative Clarification** - Confidence-driven Q&A workflow (mandatory before PRD generation)
- **JIRA Ticket Generation** - Ready-to-import epics, stories, and tasks with story points
- **Automatic Test Case Generation** - Generate test cases from requirements
- **OpenAPI Specification Generation** - Automatic API endpoint documentation
- **Automatic Database Setup** - PostgreSQL + pgvector via Docker/Colima (zero manual configuration)
- **100% Local Execution** - Privacy-first, code never leaves your machine
- **Multi-Provider AI Support** - Anthropic Claude, OpenAI GPT-4, Google Gemini, Apple Intelligence (requires macOS 26.0 Tahoe)
- **Complete Swift Library** - 880 source files with clean architecture
- **Comprehensive Documentation** - README, PREREQUISITES, installation guide, usage examples

### Technical Details
- Clean Architecture with strict layer isolation (Domain/Application/Infrastructure/Composition)
- Zero framework dependencies in domain layer
- Actor-based concurrency for thread-safe operations
- Swift 5.9+ compatible with Package Manager
- macOS 13+ and Linux (Ubuntu 20.04+) support
- Automatic setup scripts with prerequisite verification

### Documentation
- Step-by-step installation guide
- Comprehensive prerequisites guide with verification commands
- Usage examples (basic PRD, with mockup, with codebase)
- Configuration guide for all features
- Submission checklist and verification reports
- Distribution and deployment guides

### Security & Privacy
- All processing happens locally
- No data transmission to external services (except user's own AI provider)
- User provides their own API keys
- No telemetry or usage tracking
- Local PostgreSQL database for embeddings

[1.0.0]: https://github.com/cdeust/ai-prd-generator/releases/tag/v1.0.0
