---
description: Design review - repo-expert gathers context, then architect and DX reviewers analyze in parallel
argument-hint: <scope (feature, area, or topic)>
---
Execute this workflow:

1. First, use Task with `subagent_type: "repo-expert"` to gather all code and context relevant to: $ARGUMENTS
2. Then run two reviewers in parallel by issuing both Task calls in a single response, each receiving the repo-expert's findings in their prompt:
   - Task with `subagent_type: "architect-reviewer"`: Review the design and architecture based on the repo-expert findings
   - Task with `subagent_type: "dx-reviewer"`: Review developer experience and clarity based on the repo-expert findings

Synthesize both perspectives into actionable recommendations.
