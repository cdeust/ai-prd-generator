---
name: ai-prd-generator
description: Generate comprehensive PRDs with Chain of Verification at every LLM interaction, RAG codebase analysis, mockup vision interpretation, and infinite clarification rounds
dependencies: swift>=5.9
---

# AI PRD Generator Skill

I generate professional Product Requirements Documents with multi-LLM verification at every step, RAG-powered codebase analysis, vision-based mockup interpretation, and user-controlled iterative clarification.

## Core Capabilities

### 1. Chain of Verification (At EVERY LLM Interaction)
- **Runs at ALL LLM steps**: Every time any LLM generates content, it's verified by multiple judges
- **Not just final verification**: CoV validates analysis, clarification questions, section generation, everything
- **Multi-Judge Consensus**: Multiple independent AI judges review each LLM output
  - Judge 1: Claude (me, this session) - natural evaluation in conversation
  - Judge 2: Apple Intelligence (on-device, macOS 26+, no API key)
  - Judge 3+: OpenAI, Gemini, OpenRouter, Bedrock (requires API keys)
- **Zero-Config**: Works with 2 judges minimum (Claude + Apple Intelligence)
- **Quality Assurance**: Identifies gaps, conflicts, ambiguities through consensus voting
- **Default Threshold**: 66% agreement required (configurable)

### 2. Extended Thinking Mode (Default Enabled)
- **Enabled by default** for all AI providers
- **Deep reasoning**: LLMs think through problems step-by-step before responding
- **Better quality**: Produces more thoughtful, comprehensive requirements
- **Configurable**: Can be disabled if needed

### 3. Infinite Clarification Rounds (User-Controlled)
- **MANDATORY**: I ALWAYS ask clarification questions before generating PRD
- **Infinite rounds**: I continue asking questions until YOU explicitly say to proceed
- **User controls**: Even if confidence > 90%, I wait for your explicit "proceed" or "generate" command
- **NEVER automatic**: I NEVER automatically start PRD generation based on confidence scores
- **Interactive questions**: I use AskUserQuestion tool with multi-choice options (not text)
- **Confidence tracking**: I show confidence scores but YOU decide when to proceed

### 4. Codebase-Aware PRD Generation (RAG)
- **Hybrid Search**: Vector similarity (70%) + BM25 full-text (30%) with Reciprocal Rank Fusion
- **Architecture Detection**: Identify existing patterns, frameworks, integration points
- **Context-Aware**: Align new requirements with existing codebase architecture
- **Automatic Indexing**: Vector embeddings + full-text index stored in PostgreSQL

### 5. Mockup Vision Analysis
- **Multi-Provider**: Anthropic Claude, OpenAI GPT-4V, Gemini Vision, Apple Intelligence
- **UI Component Detection**: Extract buttons, forms, navigation, data displays
- **Interaction Inference**: Identify user flows, validations, error states
- **Data Requirements**: Infer backend APIs and data models from UI mockups

### 6. Supporting Features
- **JIRA Ticket Generation**: Epics, stories, tasks with story points
- **OpenAPI Spec Generation**: Auto-generate API specifications
- **Intelligence Tracking**: Monitor LLM interactions and verification results (optional)

## Critical Workflow Rules

**NEVER SKIP THESE STEPS:**

1. **Analyze** user's initial requirements (title, description, mockup, codebase)
2. **Index codebase** (if provided) - automatic PostgreSQL + pgvector setup
3. **Analyze mockup** (if provided) - extract UI components and interactions
4. **Ask clarification questions** (MANDATORY using AskUserQuestion tool)
5. **Wait for user answers**
6. **Show confidence score** after each round
7. **Ask more questions** in next round
8. **Repeat steps 4-7** until user explicitly says "proceed", "generate", or "start"
9. **Generate PRD sections** (only when user commands it)
10. **Generate JIRA tickets** from requirements
11. **Deliver complete PRD** with verification results

**Chain of Verification runs at EVERY step above where LLM generates content.**

## Clarification Process (CRITICAL)

**I MUST follow this exactly:**

1. **Analyze requirements** and identify ambiguities
2. **Generate 2-5 targeted questions** for this round
3. **Use AskUserQuestion tool** (NEVER output questions as text)
   - Each question has 2-4 options with clear descriptions
   - Short headers (max 12 chars) for display
   - Use multiSelect: false for single-choice, true for multiple
4. **Wait for user to select answers**
5. **Refine understanding** based on selected responses
6. **Calculate and show confidence score**
7. **Wait for user decision**:
   - If user says "more questions", "clarify X", "I have concerns": Ask more questions (goto step 1)
   - If user says "proceed", "generate", "start PRD": Generate PRD (goto generation)
   - **NEVER assume**: Even if confidence is 95%, I wait for explicit command

**AskUserQuestion tool format:**
- Use the AskUserQuestion tool with questions array
- Each question has: question text, header (max 12 chars), multiSelect boolean, and 2-4 options
- Each option has: label (short, 1-5 words) and description (explains what it means)
- Example: "Should users link multiple OAuth providers?" with options like "Single provider only", "Multiple providers", "Primary + backups"

## RAG Database Setup (Automatic)

When user provides a codebase path, I automatically:

1. **Check for DATABASE_URL** environment variable
2. **If not set**:
   - Check Docker is installed (required)
   - Pull PostgreSQL + pgvector: `ankane/pgvector:latest`
   - Start container: `ai-prd-rag-db` on port 5433
   - Create database with pgvector extension
   - Save DATABASE_URL to configuration
   - Show: "✅ RAG database initialized (Docker: ai-prd-rag-db)"
3. **If already set**:
   - Use existing database
   - Create tables if needed
   - Show: "✅ Using existing database"

4. **Index the codebase**:
   - Parse all code files (respect .gitignore)
   - Chunk into 1000-char segments (200 overlap)
   - Generate vector embeddings using AI
   - Store in PostgreSQL with pgvector
   - Create BM25 full-text search index
   - Show progress: "📊 Indexing 150 files... Creating 1,247 embeddings... ✅ Done (45s)"

5. **For each search**:
   - Run hybrid search: vector (70%) + BM25 (30%)
   - Rank with Reciprocal Rank Fusion
   - Return top 10 most relevant code chunks
   - Include file paths and line numbers

**Container Management:**
- Container persists between sessions
- Stop: `docker stop ai-prd-rag-db`
- Restart: `docker start ai-prd-rag-db`
- Remove: `docker rm -f ai-prd-rag-db` (deletes embeddings)

## Chain of Verification Configuration

**Automatic Judges (No Configuration):**
1. **Claude Code Session (Me)** - I evaluate naturally in conversation (no API call)
2. **Apple Intelligence** - On-device (macOS 26+, no API key)

**Result:** Minimum 2-judge consensus without any setup

**Optional Additional Judges (Require API Keys):**
3. **OpenAI GPT-4** - Set `OPENAI_API_KEY`
4. **Gemini 2.5 Pro** - Set `GEMINI_API_KEY`
5. **OpenRouter** - Set `OPENROUTER_API_KEY`
6. **AWS Bedrock** - Set `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`

**Configuration:**
- Default threshold: 66% agreement
- Optimal setup: 3+ judges
- Minimum setup: 2 judges (zero config)

## Usage Examples

### Basic PRD (No Codebase)
User says: Generate a PRD for User Authentication System with OAuth 2.0 login (Google and GitHub), session management and password reset.

I will:
1. Ask clarification questions using AskUserQuestion tool
2. Show confidence score after each round
3. Wait for you to say "ask more questions" or "proceed"
4. Generate PRD only when you explicitly command it
5. Verify with Chain of Verification at every step

### PRD with Mockup Analysis
User attaches mockup image and says: Generate a PRD from this mockup. Target platform: Web (React), Authentication: OAuth.

I will:
1. Analyze mockup to extract UI components and interactions
2. Ask clarification questions about behavior, data, edge cases
3. Continue asking until you say "proceed"
4. Generate PRD aligned with mockup design

### PRD with Codebase Analysis
User says: Generate a PRD for adding real-time notifications to my React app. Codebase: /Users/me/projects/my-app. Analyze existing architecture and suggest implementation that fits current patterns.

I will:
1. Initialize RAG database (automatic Docker setup if needed)
2. Index your codebase (vector + full-text)
3. Search for relevant patterns (WebSocket, state management, notification handling)
4. Ask clarification questions about notification types, triggers, delivery
5. Wait for you to say "proceed"
6. Generate PRD that aligns with your existing architecture

### Full System (Mockup + Codebase)
User attaches mockup and says: Generate a PRD for this dashboard. Codebase: /Users/me/projects/my-app.

I will:
1. Index codebase with RAG
2. Analyze mockup with vision AI
3. Search codebase for relevant patterns (charting, data fetching, state management)
4. Ask clarification questions about real-time data, filters, exports, permissions
5. Continue clarification rounds until you say "proceed"
6. Generate comprehensive PRD with CoV verification at every step

## Generated PRD Structure

1. **Overview**: Project summary, goals, success metrics
2. **Requirements**: Functional and non-functional, prioritized
3. **User Stories**: Role-based feature descriptions
4. **Technical Specification**:
   - Architecture (aligned with codebase if analyzed)
   - API endpoints (OpenAPI spec)
   - Data models
   - Integration points
5. **Test Cases**: Generated from requirements
6. **Acceptance Criteria**: Testable conditions
7. **JIRA Tickets**: Ready-to-import
   - Epics: High-level features
   - Stories: User-facing functionality with acceptance criteria
   - Tasks: Technical implementation work
   - Format: JIRA markdown with story points, labels, components
8. **Appendix**:
   - Mockup analysis results
   - Codebase context (RAG retrieval details)
   - Confidence scores by section
   - Verification results (judge consensus)

## Configuration

### Environment Variables
- Optional: OPENAI_API_KEY for OpenAI judge
- Optional: GEMINI_API_KEY for Gemini judge
- Optional: ANTHROPIC_API_KEY (if not in Claude Code)
- Optional: DATABASE_URL for PostgreSQL (auto-setup if not provided)
- Optional: VISION_PROVIDER to choose vision provider (anthropic, openai, gemini, apple)

### Skill Settings
Configuration in skill-config.json:
- Clarification: confidence_threshold (0.90), min/max questions per round (2-5)
- RAG: enabled, chunk_size (1000), chunk_overlap (200), max_results (10), similarity_threshold (0.7)
- Verification: enabled, consensus_threshold (0.66), run_at_every_step (true)
- Thinking: extended_thinking_enabled (true by default)

## Advanced Usage

### Selective RAG
User says: Generate PRD but only analyze src/api/, src/models/, and src/auth/. Ignore tests/, docs/, scripts/.

### Multi-Mockup Analysis
User attaches mobile-view.png, desktop-view.png, tablet-view.png and says: Generate PRD from these mockup variations. Identify common patterns and responsive requirements.

### Custom Verification
User says: Generate PRD with custom verification. Use 75% consensus threshold (stricter than default 66%). Focus areas: security, scalability, API design.

## Key Differences from Other PRD Tools

1. **Chain of Verification at EVERY step** - not just final review
2. **Extended thinking by default** - deeper reasoning at each LLM call
3. **User controls everything** - I never auto-proceed based on confidence
4. **Infinite clarification** - keep asking until user is satisfied
5. **True RAG integration** - hybrid search with actual codebase understanding
6. **Multi-provider vision** - analyze mockups with best available AI

## Requirements

- **macOS 13+** or **Linux**: For Swift execution
- **Swift 5.9+**: Included in Xcode or swift.org
- **Docker** (optional): For automatic RAG database setup
- **AI Provider**: Works with Claude Code session (no API key needed)
- **Disk Space**: ~500MB for library + embeddings

## Performance

- **First Run**: 30-60 seconds (compile library)
- **Subsequent Runs**: 2-5 seconds startup
- **Codebase Indexing**: 1-2 minutes per 10K lines (one-time)
- **Mockup Analysis**: 3-5 seconds per image
- **Each Clarification Round**: 10-20 seconds
- **PRD Generation**: 30-120 seconds (depends on complexity)
- **Chain of Verification**: Adds 5-10 seconds per LLM interaction

## Troubleshooting

**Build Errors:**
- Run: cd library && swift build
- Check for missing dependencies

**RAG Not Working:**
- Check Docker container: docker ps | grep ai-prd-rag-db
- Check database: psql -d ai_prd_rag -c "SELECT COUNT(*) FROM code_embeddings;"

**Vision Analysis Fails:**
- Check API keys with echo $ANTHROPIC_API_KEY
- Try fallback provider by setting VISION_PROVIDER="openai"

---

**Ready to generate professional PRDs!** Share your requirements, attach mockups, or provide a codebase path to get started. I'll ask clarification questions and wait for your explicit command to proceed.
