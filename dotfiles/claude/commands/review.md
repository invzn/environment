---
description: Full multi-perspective review - security, performance, architecture, and DX reviewers run in parallel
argument-hint: <scope (file path, function, or topic)>
---
Run all four reviewers in parallel by issuing four Task tool calls in a single response:

1. Task with `subagent_type: "security-reviewer"`: Review for security vulnerabilities and attack surface in: $ARGUMENTS
2. Task with `subagent_type: "performance-reviewer"`: Review for performance bottlenecks and scaling issues in: $ARGUMENTS
3. Task with `subagent_type: "architect-reviewer"`: Review design decisions and architecture in: $ARGUMENTS
4. Task with `subagent_type: "dx-reviewer"`: Review developer experience, clarity, and documentation in: $ARGUMENTS

After all agents complete, synthesize their findings into a unified summary with the most important issues prioritized across all perspectives.
