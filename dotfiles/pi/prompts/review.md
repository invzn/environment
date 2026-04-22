---
description: Full multi-perspective review - security, performance, architecture, and DX reviewers run in parallel
---
Use the subagent tool with the tasks parameter (parallel mode) to run all four reviewers simultaneously:

1. "security-reviewer" agent: Review for security vulnerabilities and attack surface in: $@
2. "performance-reviewer" agent: Review for performance bottlenecks and scaling issues in: $@
3. "architect-reviewer" agent: Review design decisions and architecture in: $@
4. "dx-reviewer" agent: Review developer experience, clarity, and documentation in: $@

After all agents complete, synthesize their findings into a unified summary with the most important issues prioritized across all perspectives.
