---
description: Pull request review - all four engineering perspectives review git diff changes in parallel
---
Use the subagent tool with the tasks parameter (parallel mode) to review the current changes:

1. "security-reviewer" agent: Review `git diff` for security issues in: $@
2. "performance-reviewer" agent: Review `git diff` for performance concerns in: $@
3. "architect-reviewer" agent: Review `git diff` for design and architecture quality in: $@
4. "dx-reviewer" agent: Review `git diff` for code clarity and documentation in: $@

Each agent should start by running `git diff` (or `git diff main` if appropriate) to see the changes.

After all agents complete, synthesize into a PR review summary with:
- **Must fix** (blocking issues across all perspectives)
- **Should fix** (important but non-blocking)
- **Consider** (suggestions for improvement)
- **Approval recommendation** (approve, request changes, or comment)
