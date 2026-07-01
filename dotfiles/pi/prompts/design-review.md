---
description: Design review - repo-expert gathers context, then architect and DX reviewers analyze in parallel
---
Use the subagent tool with the chain parameter:

1. First, use the "repo-expert" agent to gather all code and context relevant to: $@
2. Then, use the subagent tool with parallel tasks to run two reviewers on the findings (use {previous} placeholder):
   - "architect-reviewer" agent: Review the design and architecture based on: {previous}
   - "dx-reviewer" agent: Review developer experience and clarity based on: {previous}

Synthesize both perspectives into actionable recommendations.
