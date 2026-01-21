---
name: ai-prd-generator
description: Generate comprehensive PRDs with Chain of Verification quality assurance, RAG codebase analysis, mockup vision interpretation, and confidence-driven clarification
dependencies: swift>=5.9, python>=3.8
---

# AI PRD Generator - Full System

I generate professional Product Requirements Documents using Chain of Verification for quality assurance, RAG for codebase analysis, multi-provider vision for mockup interpretation, and confidence-driven iterative clarification.

## Capabilities

### 1. Chain of Verification (Quality Assurance)
- **Multi-LLM Consensus**: Multiple AI judges independently review PRD quality
  - **Judge 1 (Me - Claude Code Session)**: I evaluate naturally in our conversation (no external API call)
  - **Judge 2 (Apple Intelligence)**: On-device evaluation (macOS 26+, automatic, no API key)
  - **Judge 3+ (Optional)**: OpenAI, Gemini, OpenRouter, or Bedrock (requires API keys)
- **Zero-Config Operation**: 2 judges (Claude Code + Apple Intelligence) work without any API keys
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
2. **Configure AI providers**:
   - **Inside Claude Code (current session)**: No API keys required!
     - I (this Claude session) act as the primary verification judge
     - Apple Intelligence included automatically (macOS 26+, no API key)
     - Minimum 2 judges without any configuration
   - **Optional**: Set OPENAI_API_KEY, GEMINI_API_KEY, OPENROUTER_API_KEY, or AWS credentials for 3-6 judge consensus
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

## Chain of Verification Judge Configuration

**Inside Claude Code, I use myself and available AI models as judges:**

### Automatic Judges (No Configuration Required)
1. **Claude Code Session (Me)**
   - I evaluate PRD quality naturally in our conversation
   - No external Claude API calls made (detected via CLAUDECODE=1 environment variable)
   - Primary judge that understands full context of our discussion

2. **Apple Intelligence**
   - On-device evaluation (macOS 26+, always attempted)
   - Zero API calls, complete privacy
   - Fast, local processing
   - No API key required

**Result:** Minimum 2-judge consensus without any configuration or API keys

### Optional Additional Judges (Requires API Keys)
3. **OpenAI GPT-4** - Set `OPENAI_API_KEY` environment variable
4. **Gemini 2.5 Pro** - Set `GEMINI_API_KEY` environment variable
5. **OpenRouter** - Set `OPENROUTER_API_KEY` (access to 100+ models)
6. **AWS Bedrock** - Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

**Consensus Configuration:**
- Default threshold: 66% agreement
- Optimal setup: 3+ judges for strongest validation
- Minimum setup: 2 judges (Claude Code + Apple Intelligence, zero config)

**What the VerificationFactory does:**
```
🔍 Creating judge providers...
📱 Running inside Claude Code (authenticated session)
   Claude evaluates naturally in conversation - no API call needed
   Using Apple Intelligence + OpenAI/Gemini for programmatic consensus
✅ Apple Intelligence judge added (on-device)
✅ OpenAI judge added (gpt-4o)  [if OPENAI_API_KEY set]
✅ Created 2+ judge(s) for verification
   Multi-LLM consensus enabled with diverse models
```

---

## Usage Examples

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


### Step 1: Initial Analysis & Setup
I execute actual Swift code to initialize the library and analyze requirements:
```swift
import Foundation
import Composition

// Initialize the library with configuration
let config = try Configuration.fromEnvironment()
let composition = try await LibraryComposition.create(configuration: config)

// Create PRD request from user input
let request = PRDRequest(
    title: userTitle,
    description: userDescription,
    requirements: userRequirements,
    mockupFiles: mockupPaths,  // Optional: paths to mockup images
    codebasePath: codebasePath,  // Optional: path to codebase for RAG
    confidenceThreshold: 0.90
)
```

### Step 2: Mockup Vision Analysis (if provided)
If you attach mockup images, I analyze them with multi-provider vision:
```swift
// Vision analysis (automatic if mockup files provided)
if let mockupPath = request.mockupFiles?.first {
    let visionAnalyzer = composition.services.factory?.createVisionAnalyzer()
    let mockupAnalysis = try await visionAnalyzer?.analyze(
        imagePath: mockupPath,
        prompt: "Extract UI components, interactions, and data requirements"
    )

    // Extracts:
    // - UI components (buttons, forms, tables)
    // - User interactions and flows
    // - Data requirements and API needs
}
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

**Technical Implementation (Actual Swift Code):**
```swift
// Check if DATABASE_URL is set, otherwise setup Docker container
if ProcessInfo.processInfo.environment["DATABASE_URL"] == nil {
    // Auto-start PostgreSQL with pgvector
    try await Bash.execute("docker run -d --name ai-prd-rag-db -p 5433:5432 -e POSTGRES_PASSWORD=ai_prd_pass ankane/pgvector:latest")
    ProcessInfo.processInfo.environment["DATABASE_URL"] = "postgresql://postgres:ai_prd_pass@localhost:5433/ai_prd_rag"
}

// Index codebase (if provided)
if let codebasePath = request.codebasePath {
    let createCodebase = composition.useCases.createCodebase
    let indexCodebase = composition.useCases.indexCodebase

    let codebase = try await createCodebase.execute(name: "user-project", path: codebasePath)
    try await indexCodebase.execute(codebaseId: codebase.id)
}

// Search codebase for relevant context
if let hybridSearch = composition.services.hybridSearch {
    let results = try await hybridSearch.search(
        query: "authentication patterns",
        projectId: codebase.id,
        limit: 10,
        similarityThreshold: 0.7
    )
    // Results contain ranked code chunks with file paths and line numbers
}
```


### Step 4: Clarification Questions (MANDATORY)

**I MUST ask clarification questions before generating the PRD.**

**CRITICAL: I MUST use the `AskUserQuestion` tool to present interactive multi-choice questions.**
- DO NOT output questions as text - always use the tool
- Each question must have 2-4 options with clear descriptions
- Questions should have short headers (max 12 chars) for display
- Use multiSelect: false for single-choice, true for multiple selections

**Process:**
1. I analyze the requirements and identify ambiguities
2. I generate 2-5 targeted clarification questions
3. I use `AskUserQuestion` tool to present interactive options (NOT text output)
4. I wait for user to select their answers
5. I refine my understanding based on selected responses
6. I re-calculate confidence score
7. If confidence < 90%, I repeat with more questions using AskUserQuestion
8. Once confidence >= 90%, I proceed to PRD generation

**Example - How I Use AskUserQuestion Tool:**
```json
{
  "questions": [
    {
      "question": "Should users be able to link multiple OAuth providers to one account?",
      "header": "Multi-OAuth",
      "multiSelect": false,
      "options": [
        {
          "label": "Single provider only",
          "description": "Each account uses one OAuth provider (Google OR GitHub, not both)"
        },
        {
          "label": "Multiple providers",
          "description": "Users can link both Google and GitHub to same account"
        },
        {
          "label": "Primary + backups",
          "description": "One primary OAuth, others as fallback options"
        }
      ]
    },
    {
      "question": "What should happen if OAuth provider is unavailable?",
      "header": "Fallback",
      "multiSelect": false,
      "options": [
        {
          "label": "Email/password fallback",
          "description": "Allow traditional login if OAuth fails"
        },
        {
          "label": "Error message only",
          "description": "Show error, user must wait for OAuth to recover"
        },
        {
          "label": "Cached credentials",
          "description": "Use last successful OAuth token temporarily"
        }
      ]
    }
  ]
}
```

**I present 1-4 questions at a time using AskUserQuestion tool, then refine based on selected answers.**

### Step 5: Generate PRD Document
Once confidence >= 90%, I generate the complete PRD:
```swift
// Execute PRD generation with all context
let generatePRD = composition.useCases.generatePRD
let prdDocument = try await generatePRD.execute(request: request)

// Generated PRD includes:
// - Executive Summary
// - Requirements (functional & non-functional)
// - User Stories
// - Technical Specifications
// - Test Cases
// - Acceptance Criteria
// - JIRA Tickets (epics, stories, tasks)
```

### Step 6: Chain of Verification (Quality Assurance)
After generating the PRD, I verify it with multi-LLM consensus:
```swift
// Multi-judge verification for quality assurance
let verifyPRD = composition.useCases.verifyPRD
let verification = try await verifyPRD.execute(
    prdId: prdDocument.id,
    judgeCount: 3,  // Default: 3 independent AI judges
    consensusThreshold: 0.66  // Require 66% agreement
)

// Each judge reviews independently:
// - Completeness: Are all requirements captured?
// - Consistency: Do sections align with each other?
// - Clarity: Are requirements unambiguous?
// - Testability: Can requirements be validated?

// Consensus resolution identifies:
// - Gaps (missing requirements flagged by multiple judges)
// - Conflicts (contradictions between sections)
// - Ambiguities (unclear language requiring clarification)

// I automatically refine PRD if consensus < threshold
if verification.consensusScore < 0.66 {
    // Refine and regenerate based on judge feedback
    let refinedPRD = try await generatePRD.execute(
        request: request,
        verificationFeedback: verification.feedback
    )
}

// Result: High-quality PRD validated by multiple AI models
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
