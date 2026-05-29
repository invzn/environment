---
description: Query the knowledge base using the kb-curator subagent — search, synthesize, and optionally file the answer
argument-hint: <question>
---
Use the Task tool to delegate to the `kb-curator` agent (subagent_type: "kb-curator") with this task:

Answer this question using the knowledge base: $ARGUMENTS

Read `index.md` first to find relevant pages, then read those pages and synthesize an answer with citations using wikilinks. If the answer is valuable enough to keep, file it as a new page in the appropriate domain folder, update the domain's `_overview.md`, `index.md`, and `log.md`.
