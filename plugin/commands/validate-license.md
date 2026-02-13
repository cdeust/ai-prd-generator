---
description: Check current license tier, activate a license key, or view available features
---

# Validate License

If the user provided a license key in `$ARGUMENTS` (starts with `AIPRD-`), call the `activate_license` MCP tool with that key to activate it. Display the activation result.

Otherwise, call the `validate_license` MCP tool to check the current license status.
The MCP server automatically handles dual-mode validation:
- **CLI mode:** Delegates to `~/.aiprd/validate-license` binary (Ed25519 + hardware fingerprint)
- **Cowork mode:** Uses in-plugin file-based validation with Ed25519 signature verification

Then call `get_license_features` to get the full feature set for the current tier.

Display the results as a formatted banner:

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

If the MCP server is not connected, suggest reinstalling the plugin or checking the `.mcp.json` configuration.
