# AI PRD Generator Plugin

This is the ai-prd-generator plugin repository. Run `./scripts/setup.sh` to install the skill and commands into Claude Code.

## Cowork Mode — IMPORTANT

When running in **Cowork** (Claude's hosted VM environment), the plugin analyzes your codebase from **locally shared directories**. GitHub API and `gh` CLI are blocked in Cowork VMs.

**Before using any PRD generation or codebase indexing command in Cowork, you MUST share your project folder** with the Cowork session. The plugin uses Glob, Grep, and Read tools on the shared directory to analyze your codebase — no GitHub access needed.

If no project folder is shared, the plugin cannot perform codebase analysis and will ask you to either share a directory or paste code manually.

## Slash Commands

After setup, the following slash commands are available from any Claude Code session:

- `/ai-prd-generator:validate-license AIPRD-key` — activate a license key
- `/ai-prd-generator:validate-license` — check current license tier
- `/ai-prd-generator:generate-prd` — generate a PRD
- `/ai-prd-generator:index-codebase` — index a codebase for RAG
- `/ai-prd-generator` — main skill (full PRD generation workflow)

## License Flow

Before any PRD generation or codebase indexing, resolve the license tier:

1. Read `~/.aiprd/license-key` with the Read tool.
2. If the file exists and contains a key starting with `AIPRD-`: tier is **licensed**. No API call. Proceed.
3. If the file does not exist or is empty: ask the user "Would you like to enter a license key or continue with free tier?"
   - **User enters a key** → validate it via the activation procedure below. If valid → licensed. If invalid → free.
   - **User continues without** → free tier.

## License Key Activation (only when user provides a new key)

When the user provides an AIPRD- key (either during the license flow above or via "validate license key AIPRD-..."):

1. Create `~/.aiprd` directory if needed: `mkdir -p ~/.aiprd`
2. Validate the key via Bash with curl:
   - POST to `https://api.polar.sh/v1/customer-portal/license-keys/validate` with JSON `{"key":"THE_KEY","organization_id":"3c29257d-7ddb-4ef1-98d4-3d63c491d653"}`
   - If not `"status":"granted"`, retry with `https://sandbox-api.polar.sh/v1/customer-portal/license-keys/validate` and `organization_id` `33bddceb-c04b-40f7-a881-54402f1ddd4f`
3. If granted: save key to `~/.aiprd/license-key` with Write tool, display licensed banner.
4. If both reject: tell user the key is invalid, proceed with free tier.

Do NOT call the Polar.sh API when a key is already saved. The API has validation limits.
Do NOT search the codebase for license validation logic. These instructions are complete.
