---
description: Pull request review - all four engineering perspectives review git diff changes in parallel
argument-hint: <optional context about the PR>
---
Run all four reviewers on the current diff in parallel by issuing four Task tool calls in a single response:

1. Task with `subagent_type: "security-reviewer"`: Review `git diff` for security issues in: $ARGUMENTS
2. Task with `subagent_type: "performance-reviewer"`: Review `git diff` for performance concerns in: $ARGUMENTS
3. Task with `subagent_type: "architect-reviewer"`: Review `git diff` for design and architecture quality in: $ARGUMENTS
4. Task with `subagent_type: "dx-reviewer"`: Review `git diff` for code clarity and documentation in: $ARGUMENTS

Each agent should start by running `git diff` (or `git diff main` if appropriate) to see the changes.

After all agents complete, synthesize into a PR review summary with:
- **Must fix** (blocking issues across all perspectives)
- **Should fix** (important but non-blocking)
- **Consider** (suggestions for improvement)
- **Approval recommendation** (approve, request changes, or comment)
