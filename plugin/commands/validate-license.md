---
description: Check current license tier and available features
---

# Validate License

Call the `validate_license` MCP tool to check the license status.
The MCP server automatically handles dual-mode validation:
- **CLI mode:** Delegates to `~/.aiprd/validate-license` binary (Ed25519 + hardware fingerprint)
- **Cowork mode:** Uses in-plugin file-based validation

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

If the tier is `free`, mention that a 14-day trial is available and that a full license can be purchased at https://aiprd.dev/purchase.

If the tier is `trial`, show days remaining and the purchase URL.

If the MCP server is not connected, suggest reinstalling the plugin or checking the `.mcp.json` configuration.
