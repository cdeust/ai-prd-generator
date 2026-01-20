---
name: ai-prd-generator
description: Generate comprehensive PRDs with Chain of Verification quality assurance, RAG codebase analysis, mockup vision interpretation, and confidence-driven clarification
dependencies: swift>=5.9, python>=3.8
---

# AI PRD Generator - Full System

I generate professional Product Requirements Documents using Chain of Verification for quality assurance, RAG for codebase analysis, multi-provider vision for mockup interpretation, and confidence-driven iterative clarification.

## Capabilities

### 1. Chain of Verification (Quality Assurance)
- **Multi-LLM Consensus**: 3+ AI judges independently review PRD quality
- **Consensus Resolution**: Identifies gaps, conflicts, and ambiguities through voting
- **Quality Scoring**: Quantifies completeness, consistency, and clarity
- **Automatic Refinement**: Iterates until consensus threshold met (default: 66%)
- **Production-Proven**: Most reliable quality mechanism for requirement validation

### 2. Codebase-Aware PRD Generation (RAG)
- **RAG (Retrieval Augmented Generation)**: Analyze existing codebases to inform PRD decisions
- **Hybrid Search**: Vector similarity + BM25 full-text search with Reciprocal Rank Fusion
- **Architecture Detection**: Identify patterns, frameworks, and integration points
- **Context-Aware Requirements**: Align new features with existing architecture

### 3. Mockup Analysis (Vision)
- **Multi-Provider Support**: Anthropic Claude, OpenAI GPT-4V, Gemini Vision, Apple Intelligence
- **UI Component Detection**: Extract buttons, forms, navigation, data displays
- **Interaction Inference**: Identify user flows, validations, error states
- **Data Requirements**: Infer backend APIs and data models from UI

### 4. Iterative Clarification
- **Confidence Scoring**: Multi-pass analysis to identify ambiguous requirements
- **Targeted Questions**: Ask only high-value clarifying questions
- **Adaptive Refinement**: Continue until confidence threshold met (default: 90%)
- **User-Driven**: You control when to stop refining based on confidence level

### 5. Supporting Features
- **Test Generation**: Automatic test cases and acceptance criteria from requirements
- **OpenAPI Spec Generation**: Auto-generate API specifications for endpoints
- **Intelligence Tracking**: Monitor LLM interactions and quality metrics (optional)
- **Thinking Strategies**: Chain-of-Thought, Tree of Thought, ReAct (experimental, optional)

## Setup

The skill includes the full Swift library for local execution. On first use, I'll:

1. **Build the library**: Compile Swift Package Manager project
2. **Configure AI providers**: Use your API keys (Anthropic, OpenAI, or Apple Intelligence)
3. **Initialize RAG database** (AUTOMATIC):
   - Check if DATABASE_URL is set
   - If NOT set → I will automatically start a local PostgreSQL container with pgvector
   - Create database tables and enable vector extension
   - Index your codebase and create embeddings

**RAG Database Setup is AUTOMATIC:**
- On first use with codebase analysis, I will:
  1. Check for Docker (required for automatic setup)
  2. Pull PostgreSQL + pgvector image (ankane/pgvector)
  3. Start container: `ai-prd-rag-db` on port 5433
  4. Create database and enable pgvector extension
  5. Set DATABASE_URL automatically in skill configuration
  6. Index your codebase and store embeddings

**If you already have PostgreSQL:**
- Set `DATABASE_URL="postgresql://user:pass@host:port/dbname"`
- I will use your existing database instead

**No manual setup required - it just works!**


### Basic PRD (No Codebase)
```
Generate a PRD for:
Title: "User Authentication System"
Description: "Add OAuth 2.0 login with Google and GitHub, including session management and password reset"
```

### PRD with Mockup Analysis
```
Generate a PRD from this mockup:
[Attach image file]

Additional context:
- Target platform: Web (React)
- Authentication: OAuth
```

### PRD with Codebase Analysis
```
Generate a PRD for adding real-time notifications to my React app.

Codebase: /Users/me/projects/my-app
Analyze the existing architecture and suggest implementation that fits the current patterns.
```

### Full System (Mockup + Codebase)
```
Generate a PRD for the dashboard shown in this mockup:
[Attach mockup]

Codebase: /Users/me/projects/my-app
Use RAG to understand:
- Current data fetching patterns
- State management approach
- Component structure
**CRITICAL: I ALWAYS follow this workflow - no shortcuts:**

### Workflow Overview
1. **Analyze** initial requirements (title, description, mockup, codebase)
2. **Initialize** RAG database (AUTOMATIC - Docker container with pgvector if needed)
3. **Index** codebase (if provided) - Create vector embeddings automatically
4. **Ask** clarification questions (MANDATORY - never skip)
5. **Wait** for user answers
6. **Refine** understanding and regenerate questions if confidence < 90%
7. **Generate** PRD sections once confidence >= 90%
8. **Create** JIRA tickets (epics, stories, tasks with story points)
9. **Verify** with Chain of Verification (multi-judge consensus)
10. **Deliver** final PRD with JIRA tickets and verification results

**I will NOT generate a PRD without first:**
- Initializing RAG database (automatic Docker setup if needed)
- Indexing the codebase (if provided)


### Step 1: Initial Analysis
I analyze your input using the library's analysis pipeline:
```python
# The skill executes this via the library
analysis = await prd_library.analyze_requirements(
    title=title,
    description=description,
    mockup_files=mockup_paths,
    codebase_path=codebase_path
)
```

### Step 2: Mockup Vision Analysis (if provided)
```python
# Multi-provider vision analysis
mockup_analysis = await prd_library.analyze_mockup(
    image_path=mockup_path,
    provider="anthropic"  # or openai, gemini, apple
)

# Extracts:
# - UI components and interactions
# - Data requirements
# - Technical implications
```

### Step 3: Codebase RAG (if provided)

**If you provide a codebase path, I WILL automatically:**

1. **Initialize RAG Database** (First Time - Fully Automatic)
   - Check if DATABASE_URL environment variable is set
   - If NOT set:
     - Check Docker is installed (required)
     - Pull PostgreSQL + pgvector image: `ankane/pgvector:latest`
     - Start container: `ai-prd-rag-db` on port 5433
     - Create database `ai_prd_rag` with pgvector extension
     - Save DATABASE_URL to skill config: `postgresql://postgres:ai_prd_pass@localhost:5433/ai_prd_rag`
     - Show: "✅ RAG database initialized (Docker container: ai-prd-rag-db)"
   - If already set:
     - Use your existing database
     - Create tables if they don't exist
     - Show: "✅ Using existing database"

2. **Index the Codebase** (First Time or When Updated)
   - Parse all code files (respecting .gitignore)
   - Chunk files into analyzable segments (1000 chars with 200 overlap)
   - Generate vector embeddings for each chunk using AI
   - Store embeddings in PostgreSQL with pgvector
   - Create BM25 full-text search index
   - Cache metadata for future runs
   - Show progress: "📊 Indexing 150 files... Creating 1,247 embeddings... ✅ Done (45s)"

3. **Retrieve Relevant Context** (Every Time)
   - Run hybrid search: vector similarity (70%) + BM25 keyword (30%)
   - Rank results using Reciprocal Rank Fusion
   - Extract top 10 most relevant code chunks
   - Include in PRD context with file paths and line numbers

**I will show you:**
```
📊 RAG Codebase Analysis
- Database: ai-prd-rag-db (Docker container on port 5433) ✅ Running
- Indexed: 150 files (45s)
- Embeddings: 1,247 chunks stored in PostgreSQL
- Search: "authentication patterns" → 10 results (0.87 avg relevance)

Top Code Context:
1. src/auth/oauth.ts:15-45 (relevance: 0.94)
   - OAuth2 implementation with Google/GitHub
2. src/middleware/jwt.ts:8-32 (relevance: 0.89)
   - JWT token validation middleware
...
```

**Container Management:**
- Container persists between sessions (data preserved)
- To stop: `docker stop ai-prd-rag-db`
- To restart: `docker start ai-prd-rag-db`
- To remove: `docker rm -f ai-prd-rag-db` (deletes all embeddings)

**Technical Implementation:**
```python
# This is what I execute behind the scenes
if not os.getenv("DATABASE_URL"):
    # Auto-start PostgreSQL container
    await setup_rag_database()
    
await prd_library.index_codebase(
    path=codebase_path,
    project_name="my-app"
)
context = await prd_library.search_codebase(
    query="authentication patterns",
    project_name="my-app",
    limit=10
)
```


### Step 4: Clarification Questions (MANDATORY)

**I MUST ask clarification questions before generating the PRD.**

**Process:**
1. I analyze the requirements and identify ambiguities
2. I generate 2-5 targeted clarification questions
3. I present the questions to you with current confidence score
4. I wait for your answers (DO NOT proceed without answers)
5. I refine my understanding based on your responses
6. I re-calculate confidence score
7. If confidence < 90%, I repeat with more questions
8. Once confidence >= 90%, I proceed to PRD generation

**Example Questions I Might Ask:**
- "Should users be able to link multiple OAuth providers to one account?"
- "What should happen if OAuth provider is down? Fallback to email/password?"
- "Should session timeout be configurable per user, or system-wide?"
- "Do you need MFA (multi-factor authentication) support?"

```python
# Library implementation (for reference)
while confidence < 0.90:
    questions = await prd_library.generate_clarification_questions(
        current_prd=prd,
        confidence_score=confidence
    )
    answers = await prompt_user(questions)
    prd = await prd_library.refine_prd(prd, answers)
    confidence = await prd_library.score_confidence(prd)
```
```

### Step 5: Chain of Verification (Quality Assurance)
```python
# Multi-LLM consensus - The most reliable quality mechanism
verification = await prd_library.verify_prd(
    prd=prd,
    judges=["claude-opus", "gpt-4", "gemini-pro"]  # 3+ independent judges
)

# Each judge reviews independently:
# - Completeness: Are all requirements captured?
# - Consistency: Do sections align with each other?
# - Clarity: Are requirements unambiguous?
# - Testability: Can requirements be validated?

# Consensus resolution identifies:
# - Gaps (missing requirements all judges notice)
# - Conflicts (contradictions between sections)
# - Ambiguities (unclear language flagged by multiple judges)

final_prd = await prd_library.resolve_disagreements(verification)

# Result: High-quality PRD validated by multiple AI models
```

### Step 6: Generate PRD Document
```python
# Generate final PRD with all sections
prd_document = await prd_library.generate_prd(
    requirements=refined_requirements,
    context=enriched_context,
    confidence_score=confidence
)
```

## Output Structure

The generated PRD includes:

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
7. **JIRA Tickets**: Ready-to-import tickets
   - **Epics**: High-level features (e.g., "User Authentication System")
   - **Stories**: User-facing functionality with acceptance criteria
   - **Tasks**: Technical implementation work
   - **Format**: JIRA-compatible markdown with story points, labels, components
   - **Example**:
     ```markdown
     ## Epic: User Authentication
     - Story Points: 21
     - Components: Auth, Security
     
     ### Story: OAuth Login
     - As a user, I want to log in with Google/GitHub
     - Acceptance Criteria:
       - [ ] User can click "Login with Google" button
       - [ ] OAuth flow redirects to provider
       - [ ] User session created on success
     - Story Points: 8
     - Labels: frontend, backend, security
     
     ### Task: Implement OAuth Provider Integration
     - Set up OAuth client credentials
     - Implement callback handler
     - Store user tokens securely
     - Story Points: 5
     - Labels: backend, security
     ```
8. **Appendix**:
   - Mockup analysis results
   - Codebase context used (with RAG retrieval details)
   - Confidence scores
   - Verification results

## Configuration

### Environment Variables
```bash
# Required: At least one AI provider
export ANTHROPIC_API_KEY="sk-ant-..."
# or
export OPENAI_API_KEY="sk-..."
# or use Apple Intelligence (macOS 13+)

# Optional: PostgreSQL for RAG
export DATABASE_URL="postgresql://localhost:5432/ai_prd"
export STORAGE_TYPE="postgres"  # or "memory"

# Optional: Confidence threshold
export PRD_CONFIDENCE_THRESHOLD="0.90"  # 0.0 to 1.0

# Optional: Vision provider preference
export VISION_PROVIDER="anthropic"  # anthropic, openai, gemini, apple
```

### Skill Settings (skill-config.json)
```json
{
  "clarification": {
    "max_rounds": 5,
    "confidence_threshold": 0.90,
    "min_questions_per_round": 2,
    "max_questions_per_round": 5
  },
  "rag": {
    "enabled": true,
    "chunk_size": 1000,
    "chunk_overlap": 200,
    "max_results": 10,
    "similarity_threshold": 0.7
  },
  "vision": {
    "provider": "anthropic",
    "fallback_providers": ["openai", "gemini"],
    "max_retries": 3
  },
  "verification": {
    "enabled": true,
    "num_judges": 3,
    "consensus_threshold": 0.66
  }
}
```

## Advanced Features

### Custom Thinking Strategies
```
Generate PRD using Tree of Thought strategy for complex multi-path analysis:
[Your requirements]

Strategy: tree-of-thought
Branching factor: 3
Max depth: 4
```

### Selective RAG
```
Generate PRD but only analyze these parts of the codebase:
- src/api/ (API layer)
- src/models/ (Data models)
- src/auth/ (Authentication)

Ignore: tests/, docs/, scripts/
```

### Multi-Mockup Analysis
```
Generate PRD from these mockup variations:
1. mobile-view.png (Mobile interface)
2. desktop-view.png (Desktop interface)
3. tablet-view.png (Tablet interface)

Identify common patterns and responsive requirements.
```

### Verification Customization
```
Generate PRD with custom verification:
Judges: claude-opus-4, gpt-4-turbo, gemini-pro-1.5
Consensus: 2/3 (66%)
Focus areas: security, scalability, API design
```

## Examples

### Example 1: Authentication System
**Input:**
```
Title: OAuth 2.0 Authentication
Description: Add Google and GitHub OAuth with session management
```

**I will:**
1. Ask clarifying questions:
   - Should users link multiple OAuth providers to one account?
   - Session timeout duration?
   - Password reset flow for email/password fallback?
2. Generate PRD with confidence score
3. Iterate until 90% confidence

### Example 2: Dashboard from Mockup
**Input:**
```
[Attach dashboard.png]
Codebase: /Users/me/my-app

Generate PRD for this analytics dashboard
```

**I will:**
1. Analyze mockup to identify:
   - Chart components (line, bar, pie)
   - Filters (date range, categories)
   - Data tables with sorting/pagination
2. Index your codebase and find:
   - Current charting libraries
   - Data fetching patterns
   - State management
3. Generate PRD aligned with your architecture
4. Ask clarifications on:
   - Real-time vs cached data
   - Export functionality
   - User permissions

### Example 3: Complex Feature with Full Analysis
**Input:**
```
[Attach 3 mockup files]
Codebase: /Users/me/ecommerce-app

Generate PRD for checkout flow redesign.
Current codebase uses: React, Redux, Stripe
Analyze payment handling and cart management patterns.
```

**I will:**
1. Analyze all 3 mockups for variations
2. RAG search for:
   - Existing Stripe integration
   - Redux cart reducers
   - Payment error handling
3. Generate comprehensive PRD
4. Use Chain of Verification for payment security
5. Iterate clarifications for edge cases
6. Provide OpenAPI spec for new endpoints

## Files Included in This Skill

```
ai-prd-generator/
├── SKILL.md                          # This file
├── skill-config.json                 # Configuration
├── library/                          # Swift library (full source)
│   ├── Sources/
│   │   ├── Domain/                  # Business entities
│   │   ├── Application/             # Use cases
│   │   ├── Infrastructure/          # AI providers, RAG, vision
│   │   └── Composition/             # Dependency injection
│   ├── Package.swift
│   └── README.md
├── scripts/
│   ├── prd-generate.py              # Python wrapper
│   ├── codebase-index.py            # RAG indexing
│   ├── mockup-analyze.py            # Vision analysis
│   └── setup.sh                     # First-time setup
└── examples/
    ├── basic-prd.md                 # Example outputs
    ├── with-mockup.md
    └── with-codebase.md
```

## Requirements

- **macOS 13+** or **Linux**: For Swift execution
- **Swift 5.9+**: Included in Xcode or swift.org
- **Python 3.8+**: For wrapper scripts
- **AI Provider API Key**: Anthropic (recommended), OpenAI, or Gemini
- **PostgreSQL** (optional): For persistent RAG storage
- **Disk Space**: ~500MB for library + embeddings

## Privacy & Security

- **Local Execution**: All code runs on your machine
- **No Data Transmission**: PRDs stay local unless you share them
- **API Keys**: Stored in environment variables, never in skill files
- **Codebase Privacy**: Your code never leaves your machine
- **Embeddings**: Stored locally in PostgreSQL or in-memory

## Performance

- **First Run**: 30-60 seconds (compile library)
- **Subsequent Runs**: 2-5 seconds startup
- **Codebase Indexing**: 1-2 minutes per 10K lines of code (one-time)
- **Mockup Analysis**: 3-5 seconds per image
- **PRD Generation**: 30-120 seconds depending on complexity
- **Clarification Rounds**: 10-20 seconds per question set

## Troubleshooting

**Build Errors:**
```bash
cd library && swift build
# Check for missing dependencies
```

**RAG Not Working:**
```bash
# Verify PostgreSQL
psql -d ai_prd -c "SELECT COUNT(*) FROM code_embeddings;"
```

**Vision Analysis Fails:**
```bash
# Check API keys
echo $ANTHROPIC_API_KEY
# Try fallback provider
export VISION_PROVIDER="openai"
```

## Updates

The skill is self-updating. Run:
```bash
cd ai-prd-generator && git pull
cd library && swift build
```

## Support

- **Documentation**: See library/README.md for detailed API docs
- **Issues**: Report at github.com/your-org/ai-prd
- **Examples**: Check examples/ folder for common patterns

---

Ready to generate professional PRDs with full AI capabilities! Share your requirements, mockups, or codebase path to get started.
