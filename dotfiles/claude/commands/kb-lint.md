---
description: Health-check the knowledge base using the kb-curator subagent — find contradictions, orphans, gaps, and stale content
---
Use the Task tool to delegate to the `kb-curator` agent (subagent_type: "kb-curator") with this task:

Perform a full lint health-check of the knowledge base:

1. Read `index.md` to get the full page catalog
2. Read pages systematically, checking for:
   - Contradictions between pages
   - Stale claims superseded by newer sources
   - Orphan pages with no inbound wikilinks
   - Important topics mentioned but lacking their own page
   - Missing cross-references (wikilinks that should exist)
   - Broken wikilinks that don't resolve to real pages
   - Domain folders missing a `_overview.md` hub page
   - Data gaps that could be filled
3. Present findings organized by severity
4. Suggest new questions to investigate and sources to look for
5. Append lint results to `log.md`
