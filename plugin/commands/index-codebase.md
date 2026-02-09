---
description: Index a codebase directory for RAG-enhanced PRD generation
---

# Index Codebase

Call the `validate_license` MCP tool to verify the current tier supports RAG features.

If the tier is `free`, inform the user that RAG indexing is limited to 1 hop depth.

Use `$ARGUMENTS` as the target directory path. If not provided, ask the user for the codebase path to index.

Verify the directory exists, then perform the indexing workflow:

1. **Scan** the directory for source files (respecting .gitignore patterns)
2. **Extract** code patterns: Repository, Service, Factory, Observer, Strategy, MVVM, Clean Architecture
3. **Identify** entities, interfaces, and dependency relationships
4. **Summarize** the codebase structure for RAG context

Store the indexed context so subsequent PRD generation can reference it for:
- Architecture-aware technical specifications
- Accurate dependency mapping
- Existing pattern detection and reuse recommendations
- Integration point identification

Report the indexing results:
```
Codebase Indexed
Path:       [directory]
Files:      [count] source files
Patterns:   [list of detected patterns]
Entities:   [count] extracted
RAG Depth:  [tier-dependent hop count]
```
