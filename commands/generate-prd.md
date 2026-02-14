---
name: generate-prd
description: Generate a production-ready PRD with verification and business KPIs
allowed-tools: Bash, Read, Write, Glob, Grep, WebFetch, WebSearch
argument-hint: "[project-description]"
---

# Generate PRD

## Step 1 — Detect mode

Check your available tools list. If a tool named `mcp__ai-prd-generator__validate_license` exists, you are in **Cowork mode**. Otherwise you are in **CLI Terminal mode**.

## Step 2 — Resolve license

**CLI Terminal mode:**

Use the Read tool to read the file `~/.aiprd/license-key`.
- If the file exists and contains a key starting with `AIPRD-`, the tier is **licensed**. No API call needed. Proceed.
- If the file does not exist or is empty, ask the user with AskUserQuestion: "No license key found. Would you like to enter a license key or continue with free tier?"
  - **Enter license key** → user provides an AIPRD- key. Validate it against the Polar.sh API (see validate-license command). If valid, save to `~/.aiprd/license-key` and set tier to **licensed**. If invalid, set tier to **free**.
  - **Continue without** → tier is **free**.

**Cowork mode:**

Call `check_health` MCP tool. Note the `environment` field:
- `environment: "cowork"` → No direct network access. Do NOT use MCP GitHub tools. Use WebFetch, WebSearch, or ask the user to paste code.
- `environment: "cli"` → Full access. Use `gh` CLI or MCP GitHub tools for repo analysis.

Then call `validate_license` MCP tool.

## Step 3 — Display license tier banner and proceed

- **Licensed**: Full access to all 8 PRD types, 15 thinking strategies, and complete verification. Proceed.
- **Trial**: Full access (14-day evaluation period) — show days remaining. Proceed.
- **Free**: Limited to feature/bug PRD types, 2 thinking strategies, basic verification. Proceed with free tier limitations.

## Step 4 — Load the full skill instructions

**MANDATORY**: Use the Read tool to read the file `~/.claude/skills/ai-prd-generator/SKILL.md`. This file contains the complete PRD generation workflow with all rules, confidence thresholds, clarification loop behavior, section generation, and verification logic. You MUST read it and follow every rule in it.

If the user provided a project description in `$ARGUMENTS`, use it as the initial input. Otherwise, ask for a project description.

Then follow the SKILL.md instructions from the beginning (starting at "CRITICAL WORKFLOW RULES") to execute the full workflow. Do NOT generate any PRD content without first completing the clarification loop as defined in the skill.
