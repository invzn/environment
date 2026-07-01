---
description: Ingest meeting notes — extract decisions, action items, and technical context into the knowledge base
argument-hint: <meeting note path or description>
---
Use the Task tool to delegate to the `kb-curator` agent (subagent_type: "kb-curator") with this task:

Ingest this meeting note into the knowledge base: $ARGUMENTS

Read the AGENTS.md schema first (especially the Meeting Notes section), then:
1. Read the meeting note
2. Extract decisions and file them into the relevant domain pages
3. Extract action items and add them to the appropriate project or career pages
4. Only create a new knowledge base page if the meeting produced significant technical content
5. Update index.md if any pages were created
6. Append to log.md what was extracted and where it went

Focus on distilling lasting knowledge — not transcribing the meeting.
