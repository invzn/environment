---
description: Ingest a source document into the knowledge base using the kb-curator subagent
argument-hint: <source path or description>
---
Use the Task tool to delegate to the `kb-curator` agent (subagent_type: "kb-curator") with this task:

Ingest this source into the knowledge base: $ARGUMENTS

Read the AGENTS.md schema first, then read the source thoroughly and:
1. Identify the appropriate domain folder (create a new one if needed)
2. Create or update pages in that domain folder
3. Update the domain's `_overview.md` hub page
4. Flag any contradictions with existing content
5. Update `index.md` and `overview.md`
6. Append to `log.md`
