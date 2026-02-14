# AI PRD Generator

Generate implementation-ready Product Requirements Documents with SQL DDL, API specs, domain models, JIRA tickets, test cases, and claim-by-claim verification reports.

## What It Does

This plugin generates enterprise-grade PRDs through an interactive multi-round clarification workflow. It analyzes your project description (and optionally your codebase), asks targeted clarification questions until confidence reaches 95%+, then produces a complete 4-file deliverable:

- **PRD document** with full technical specifications, domain models, and API routes
- **JIRA tickets** with Fibonacci story points, acceptance criteria, and sprint phasing
- **Test cases** covering unit, integration, and e2e with traceability matrix
- **Verification report** with claim-by-claim audit trail and confidence scores

Supports 8 PRD types, 15 research-based thinking strategies, multi-judge verification, and codebase context analysis.

## Usage

### Generate a PRD

```
/ai-prd-generator:generate-prd
```

Or describe what you need directly:

```
generate a PRD for a user authentication system with OAuth2
```

The plugin will detect your project type, ask clarification questions, and generate all four output files when ready.

### With codebase context

```
/ai-prd-generator:index-codebase /path/to/your/project
```

Then generate a PRD. The plugin uses your codebase architecture, patterns, and existing code to produce more accurate specs.

### License activation

```
/ai-prd-generator:validate-license AIPRD-your-key-here
```

Check current license status:

```
/ai-prd-generator:validate-license
```

## Features

**8 PRD Types** — Feature, Bug, Incident, Proposal, MVP, POC, Release, CI/CD. Each type has a tailored clarification depth, section count, and focus area.

**15 Thinking Strategies** — Research-based selection from MIT, Stanford, Harvard, Anthropic, OpenAI, and DeepSeek papers (2024-2026). Strategies are tiered by effectiveness: Extended Thinking (TRM), Verified Reasoning, Self-Consistency, Tree of Thoughts, Graph of Thoughts, ReAct, Reflexion, and more.

**Multi-Judge Verification** — 6 algorithms including adaptive consensus with early stopping, zero-LLM graph verification, multi-agent debate, and atomic claim decomposition. Every claim in the PRD is individually verified.

**Interactive Clarification** — Confidence-driven loop with structured multi-choice questions. Licensed users get unlimited rounds with threshold-based progression (92% minimum, 95% preferred, 100% auto-generate). Free tier gets 3 rounds.

**Codebase Context Analysis** — Extracts architecture patterns (Repository, Service, Factory, MVVM, Clean Architecture), domain entities, dependencies, and baseline metrics from your codebase. References specific files and line numbers in the generated PRD.

**4-File Export** — Every generation produces `PRD-{Name}.md`, `PRD-{Name}-jira.md`, `PRD-{Name}-tests.md`, and `PRD-{Name}-verification.md`.

## How It Works

1. **License check** — Reads saved license key from `~/.aiprd/license-key`. If none found, asks whether to enter a key or continue with free tier.
2. **Input analysis** — Detects PRD type, scope, and complexity from your description. If a codebase was indexed, incorporates architecture context.
3. **Clarification loop** — Asks multi-choice questions in rounds. Confidence score increases each round. Continues until the threshold is reached or the user says "proceed".
4. **Generation** — Produces all PRD sections using the selected thinking strategy, with section-by-section verification.
5. **Export** — Writes four files to the current directory.

## Commands

| Command | Description |
|---------|-------------|
| `/ai-prd-generator:generate-prd` | Generate a PRD through the full interactive workflow |
| `/ai-prd-generator:validate-license AIPRD-key` | Activate a license key |
| `/ai-prd-generator:validate-license` | Check current license tier |
| `/ai-prd-generator:index-codebase /path` | Index a codebase for context-aware generation |

## License Tiers

**Free** — Feature and Bug PRD types, 2 thinking strategies (Zero-Shot, Chain of Thought), 3 clarification rounds, basic verification.

**Licensed** — All 8 PRD types, all 15 thinking strategies, unlimited clarification rounds, full 6-algorithm verification engine, business KPIs, priority support. Purchase at [ai-architect.tools](https://ai-architect.tools).

The plugin works fully on free tier without a license key. Licensed tier unlocks all capabilities.

## Installation

### Claude Code (CLI Terminal)

Requires Node.js 18+ and [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

```bash
git clone https://github.com/cdeust/ai-prd-generator-plugin.git
cd ai-prd-generator-plugin
./scripts/setup.sh
```

Setup symlinks the skill and commands into `~/.claude/` for global discovery. Start `claude` from any directory — no flags needed.

### Cowork (Claude Desktop)

Enable the plugin in Cowork. No setup required — the MCP server starts automatically.

## Examples

See the `examples/` directory for a complete 4-file PRD output (Snippet Library CRUD feature):

- `PRD-SnippetLibraryCRUD.md` — Full PRD with 11 sections
- `PRD-SnippetLibraryCRUD-jira.md` — JIRA tickets with story points
- `PRD-SnippetLibraryCRUD-tests.md` — Unit, integration, and e2e test cases
- `PRD-SnippetLibraryCRUD-verification.md` — Claim-by-claim verification (94% score)

## Troubleshooting

**Commands not found after setup**
Run `./scripts/setup.sh` again. Verify symlinks exist at `~/.claude/skills/ai-prd-generator/` and `~/.claude/commands/ai-prd-generator/`.

**License key not recognized**
Ensure the key starts with `AIPRD-`. Run `/ai-prd-generator:validate-license AIPRD-your-key` to activate. The key is validated once and saved locally.

**Clarification loop stuck**
At 95%+ confidence, you can say "proceed" to start generation. On free tier, generation starts automatically after 3 rounds.

## Requirements

- Node.js 18+
- Claude Code CLI or Cowork

## Author

Clement Deust (admin@ai-architect.tools)

## Version

1.0.0
