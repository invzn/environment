---
description: Run knowledge base maintenance — fix cross-references, deduplicate, update overview and index
---
Use the subagent tool to delegate to the "kb-curator" agent with this task:

Perform maintenance on the knowledge base:

1. Read `index.md` and `log.md` to understand current state
2. Verify all cross-references are bidirectional — if page A links to B, B should link back to A
3. Check `index.md` is complete and accurate (no missing or stale entries)
4. Check for duplicate or overlapping pages that should be merged
5. Update `overview.md` to reflect the current state of all knowledge
6. Append maintenance results to `log.md`
