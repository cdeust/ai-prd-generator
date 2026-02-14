---
name: validate-license
description: Validate or activate an AIPRD license key, or check current license tier
allowed-tools: Bash, Read, Write
argument-hint: "[AIPRD-license-key]"
---

# Validate License

## Step 1 — Detect mode

Check your available tools list. If a tool named `mcp__ai-prd-generator__validate_license` exists, you are in **Cowork mode**. Otherwise you are in **CLI Terminal mode**.

## Step 2 — If the user provided a license key (starts with `AIPRD-`):

**CLI Terminal mode:**

Validate the key against the Polar.sh license API. Use Bash with `curl` to make an HTTP POST request to `https://api.polar.sh/v1/customer-portal/license-keys/validate` with the JSON body containing the user's key and the organization_id `3c29257d-7ddb-4ef1-98d4-3d63c491d653`. If the response does not contain `"status": "granted"`, retry with the sandbox API at `https://sandbox-api.polar.sh/v1/customer-portal/license-keys/validate` using organization_id `33bddceb-c04b-40f7-a881-54402f1ddd4f`.

If either endpoint returns `"status": "granted"`, the key is valid. Save the key to the file `~/.aiprd/license-key` using the Write tool. Display the LICENSED banner.

If both endpoints reject the key, tell the user the key is invalid.

**Cowork mode:**

Call the `activate_license` MCP tool with `{"key": "<key>"}`.

## Step 3 — If no key was provided (just checking current tier):

**CLI Terminal mode:**

Use the Read tool to read the file `~/.aiprd/license-key`. If the file exists and contains a key starting with `AIPRD-`, the tier is **licensed**. If the file does not exist or is empty, the tier is **free**. Do NOT call the Polar.sh API — just check whether the file exists.

**Cowork mode:**

Call the `validate_license` MCP tool, then `get_license_features`.

## Step 4 — Display results

Display as a formatted banner:

```
License Status
Tier:       [free | trial | licensed]
Valid:      [yes | no]
Expiry:     [date or N/A]
Mode:       [cli | cowork]

Available Features:
- PRD Types:     [list]
- Strategies:    [count] thinking strategies
- Verification:  [basic | full]
- Business KPIs: [summary_only | full]
- Clarification: [limited | unlimited] rounds
```

If the tier is `free`, mention:
- A full license can be purchased at https://ai-architect.tools/purchase
- After purchase, activate with: `/ai-prd-generator:validate-license AIPRD-your-key-here`

If the tier is `trial`, show days remaining and the purchase URL.
