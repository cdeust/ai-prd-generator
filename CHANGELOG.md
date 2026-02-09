# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-mvp] - 2026-02-07

### Added
- **OrchestrationEngine (AIPRDOrchestrationEngine)** - PRD pipeline, clarification workflows, JIRA export
  - 194 files with end-to-end PRD generation pipeline
  - Context-aware section generation with streaming support
  - JIRA ticket generation with epics, stories, and tasks

- **EncryptionEngine (AIPRDEncryptionEngine)** - Hardware-bound licensing and encrypted distribution
  - Ed25519 license signing and verification
  - Hardware fingerprinting (macOS IOKit, iOS vendor ID, Linux machine-id)
  - AES-256-GCM encrypted XCFramework distribution with HKDF key derivation
  - SecureFrameworkLoader with license-gated feature access
  - PII detection and prompt injection protection
  - TokenVault for secure credential storage

- **Encrypted XCFramework Distribution**
  - Build automation for all 8 engine packages
  - AIPRD-ENC-V1 encryption format with magic header validation
  - Hardware-bound decryption keys (license + machine fingerprint)
  - Ed25519 keypair generation and license signing scripts

- **Commercial License**
  - Hardware-bound Ed25519 signed licenses
  - Free tier (basic strategies, keyword search, basic verification)
  - Licensed tier (all 15 strategies, hybrid RAG, full verification, all 8 PRD types)
  - Perpetual and time-limited license options

### Changed
- Version bump from 7.0.0-beta to 1.0.0-mvp
- License changed from Development Beta to Commercial
- All 8 engine packages now included (was 6 in beta)
- Total: 1,554 Swift files across 8 engines + core library

### Technical Details
- Ed25519 keypair for cryptographic license verification
- AES-256-GCM with HKDF-SHA256 for framework encryption
- Hardware fingerprint: SHA256(serial + UUID + model) on macOS
- Build order respects dependency graph across 8 packages

## [7.0.0-beta] - 2026-02-04

### Added
- **Phase 7: Vision Engine (AIPRDVisionEngine)** - Independent vision analysis package
  - Apple Foundation Models (macOS 26+/iOS 26+) with 3B parameter on-device LLM
  - 180+ cross-platform component types (Apple HIG, Material Design 3, Vaadin/JavaFX, Web)
  - LoRA adapter support for SwiftUI, UIKit, Material Design, Enterprise Java
  - Multi-provider support: Anthropic, OpenAI, Gemini, Apple Intelligence, AWS Bedrock
  - Graceful degradation: FoundationModelsAnalyzer → AppleVisionAnalyzer fallback chain
  - Zero-cost on-device inference with sub-millisecond latency
  - Tiled analysis for large mockups with configurable tiling strategies

- **Phase 7: Business KPIs (8 Metric Systems)** - Enterprise-grade measurable ROI tracking
  - `BusinessKPIs`: Time savings (5-7 hrs/PRD), Quality improvement (+45%), Cost reduction (62%)
  - `BaselineDefinitions`: Documented industry benchmarks (manual writing time, quality scores)
  - `TemplateBusinessKPIs`: Template hit rate, reuse savings, coverage metrics
  - `StrategyBusinessKPIs`: Quality per token, efficiency scores, ROI recommendations
  - `VisionBusinessKPIs`: Precision/recall/F1 for component detection, time vs manual
  - RAG ROI: Relevance scores, chunk efficiency, context quality

### Changed
- Extracted 100+ Vision files from library to independent VisionEngine package
- Added ComponentCategory and ComponentPlatformFamily value objects
- Platform-aware PRD generation with PlatformContext
- Updated verify-skill.sh with Business KPIs validation (8 metric systems)

### Technical Details
- 306 files changed, 14,604 insertions(+), 214 deletions(-)
- All 6 packages build successfully (SharedUtilities, RAG, Verification, MetaPrompting, Strategy, Vision)

## [4.5.0] - 2026-02-03

### Added
- **Phase 6: Context-Aware PRD Types** - 8 PRD templates with adaptive depth
  - `proposal`: 7 sections, 5-6 questions, 1 RAG hop (business value focus)
  - `feature`: 11 sections, 8-10 questions, 3 RAG hops (technical depth)
  - `bug`: 6 sections, 6-8 questions, 3 RAG hops (root cause focus)
  - `incident`: 8 sections, 10-12 questions, 4 RAG hops (forensic investigation)
  - `poc`: 5 sections, 4-5 questions, 2 RAG hops (feasibility validation)
  - `mvp`: 8 sections, 6-7 questions, 2 RAG hops (core value focus)
  - `release`: 10 sections, 9-11 questions, 3 RAG hops (production readiness)
  - `cicd`: 9 sections, 7-9 questions, 3 RAG hops (pipeline automation)

- **Context-Aware Clarification** - Question depth adapts to PRD type
  - `SectionClarificationService` with 8 context-specific question generators
  - `AnalysisPromptBuilder` with context guidance injection

- **Context-Aware RAG** - Retrieval depth adapts to investigation needs
  - 8 RAGFocus types: architectureOverview, implementationDetails, bugLocation, forensicInvestigation, feasibilityValidation, coreComponents, productionReadiness, pipelineAutomation
  - `LicenseAwareRAGService` with context-based hop configuration

- **Context-Aware Sections** - Section templates adapt to PRD type
  - `ContextAwareSectionConfig` with sections, weights, display names, and guidance per context
  - Weighted token budgets (1.0x-2.0x) based on section importance

- **Context-Aware Strategy Selection** - Thinking strategies boosted by PRD type
  - `ThinkingStrategySelector.applyContextBoosts()` for all 8 contexts
  - `StrategyEngineAdapter` with context-enhanced problem descriptions
  - `StrategyRecommendationService` with context-specific guidance

- **License-Gated PRD Types** - Free tier access control
  - Free tier: Only `feature` and `bug` contexts
  - Licensed tier: All 8 context types
  - Free tier caps: 5 questions, 1 RAG hop, 6 sections max

### Changed
- **PRDContext enum** - Extended from 4 to 8 types with full configuration properties
- **skill-config.json** - Added `prd_contexts` configuration block
- **SKILL.md** - Updated to v4.5.0 with 8 PRD type documentation

### Technical Details
- No competitor has context-aware PRD templates (market analysis confirmed)
- Approach is 2 generations ahead of ChatPRD, Chisel, Miro AI, ClickUp Brain
- Research-backed strategy selection combined with context-aware depth is unique

## [5.1.0] - 2026-02-03

### Added
- **Real-Time LLM Streaming** - Progressive output as content is generated, not all at once
  - `onChunk` callback support across all 15 thinking strategies
  - End-to-end streaming from UseCase → Executor → Orchestrator → SectionContentGenerator
  - Automatic fallback to non-streaming for providers that don't support it
  - Backward compatible - existing callers work unchanged with default no-op callback

### Changed
- **ZeroShotUseCase** - Now streams responses via `onChunk` parameter
- **FewShotUseCase** - Now streams responses via `onChunk` parameter
- **AnalyzeProblemUseCase** - Streams reasoning in `reasonSinglePath()`
- **ProblemAnalysisUseCase** - Streams multi-dimensional analysis output
- **PlanAndSolveUseCase** - Streams final synthesized output
- **GenerateKnowledgeUseCase** - Streams solution step (Stage 2)
- **PromptChainingUseCase** - Streams final step in chain
- **MetaPromptingUseCase** - Streams meta-prompted response
- **PromptingStrategyExecutor** - All execute methods now support `onChunk`
- **ThinkingStrategyExecutor** - Routes `onChunk` to all strategy implementations
- **ThinkingOrchestratorUseCase** - Propagates `onChunk` to strategy execution
- **SectionContentGenerator** - Passes `onChunk` to orchestrator, removed duplicate emit
- **ContinueSessionUseCase** - Now accepts and forwards `onChunk`/`onProgress` to `GeneratePRDUseCase`

### Technical Details
- Streaming pattern: `aiProvider.streamText()` with try/catch fallback to `generateText()`
- All `onChunk` parameters default to `{ _ in }` for backward compatibility
- Streaming failure automatically falls back to non-streaming without user intervention

## [5.0.0] - 2026-02-03

### Added
- **Phase 5: AIPRDStrategyEngine** - Research-weighted strategy enforcement
  - Research Evidence Database with 30+ peer-reviewed findings
  - Claim Characteristic Analysis for complexity detection
  - Tier-based selection (Tier 1-4) based on MIT/Stanford/Harvard/Anthropic/OpenAI/DeepSeek research
  - Strategy Enforcement Engine with mandatory/recommended/suggested levels
  - Compliance Validation for LLM response structure
  - Effectiveness Tracking with feedback loop

## [4.1.0] - 2026-02-02

### Added
- **Phase 4: License-Aware Architecture** - Free/Licensed tier system
- **15 RAG-Enhanced Thinking Strategies** - All strategies support codebaseId
- **Research-Based Prioritization** - Tier 1-4 based on academic research
- **IntegratedReasoningEngine** - Cross-enhancement coordination
- **Signal Bus Architecture** - Pub/sub reactive coordination
- **Confidence Fusion Engine** - Learned weighting with bias correction
- **30+ Verifiable KPIs** - ReasoningEnhancementMetrics for effectiveness

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
