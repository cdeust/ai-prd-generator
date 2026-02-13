---
description: Index a codebase directory for RAG-enhanced PRD generation
---

# Index Codebase

First, call the `check_health` MCP tool. **Note the `environment` field** — it determines how the codebase is accessed:

- `environment: "cli"` → Local directory access. Use `$ARGUMENTS` as the target path.
- `environment: "cowork"` → **No local filesystem access to user's code.** If `$ARGUMENTS` is a GitHub URL, use WebFetch to retrieve the repo structure and key files. Otherwise, ask the user to paste relevant code or provide a GitHub URL.

Call the `validate_license` MCP tool to verify the current tier supports RAG features. If the tier is `free`, inform the user that RAG indexing is limited to 1 hop depth.

## CLI Mode

Use `$ARGUMENTS` as the target directory path. If not provided, ask the user for the codebase path to index.

Verify the directory exists, then perform the indexing workflow:

1. **Scan** the directory for source files (respecting .gitignore patterns)
2. **Extract** code patterns: Repository, Service, Factory, Observer, Strategy, MVVM, Clean Architecture
3. **Identify** entities, interfaces, and dependency relationships
4. **Summarize** the codebase structure for RAG context

## Cowork Mode

Since there is no local filesystem access to the user's codebase:

1. If `$ARGUMENTS` is a GitHub URL, use **WebFetch** to retrieve the repo structure, README, and key files
2. If `$ARGUMENTS` is text, treat it as a project description and ask the user to paste key source files
3. Extract patterns and entities from the provided context
4. Summarize the codebase structure for RAG context

Store the indexed context so subsequent PRD generation can reference it for:
- Architecture-aware technical specifications
- Accurate dependency mapping
- Existing pattern detection and reuse recommendations
- Integration point identification

Report the indexing results:
```
Codebase Indexed
Source:     [directory path | GitHub URL | user-provided]
Files:      [count] source files analyzed
Patterns:   [list of detected patterns]
Entities:   [count] extracted
RAG Depth:  [tier-dependent hop count]
Mode:       [cli | cowork]
```
