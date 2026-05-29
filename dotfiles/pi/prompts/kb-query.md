---
description: Query the knowledge base using the kb-curator subagent — search, synthesize, and optionally file the answer
---
Use the subagent tool to delegate to the "kb-curator" agent with this task:

Answer this question using the knowledge base: $@

Read `index.md` first to find relevant pages, then read those pages and synthesize an answer with citations using wikilinks. If the answer is valuable enough to keep, file it as a new page in the appropriate domain folder, update the domain's `_overview.md`, `index.md`, and `log.md`.
