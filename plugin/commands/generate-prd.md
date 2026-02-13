---
description: Generate a production-ready PRD with verification and business KPIs
---

# Generate PRD

First, call the `check_health` MCP tool to verify the server is operational. **Note the `environment` field** — it determines how codebase context is fetched:

- `environment: "cowork"` → **No direct network access.** Do NOT use MCP GitHub tools (`fetch_github_tree`, `fetch_github_file`, `github_login`). Use WebFetch, WebSearch, or ask the user to paste code instead.
- `environment: "cli"` → Full access. Use `gh` CLI or MCP GitHub tools for repo analysis.

Then call the `validate_license` MCP tool to determine the current license tier.

Display the license tier banner:
- **Licensed**: Full access to all 8 PRD types, 15 thinking strategies, and complete verification
- **Trial**: Full access (14-day evaluation period) — show days remaining
- **Free**: Limited to feature/bug PRD types, 2 thinking strategies, basic verification

If the user provided a project description in `$ARGUMENTS`, use it as the initial input. Otherwise, ask for a project description.

Now activate the `ai-prd-generator` skill to run the full PRD generation workflow:
1. Feasibility assessment
2. Context-aware clarification rounds
3. Section-by-section PRD generation with thinking strategy
4. Verification pass
5. Business KPI calculation
6. 4-file export (PRD, tests, verification, Jira tickets)

The skill handles the complete orchestration — defer to its instructions for all generation logic.
