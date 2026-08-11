---
description: Full implementation workflow (auto mode) - tech-lead agent orchestrates vertical-slice TDD, running all phases end-to-end without pausing
argument-hint: <task description>
---
Use the Agent tool with `subagent_type: "tech-lead"` to delegate this task:

Implement the following in **auto** mode: $ARGUMENTS

Run the full workflow end-to-end — discovery, planning, the TDD loop, review, and fixes — without pausing between phases.

The tech-lead owns the whole workflow and delegates to repo-expert, language experts, and reviewers itself. Do NOT do discovery, planning, implementation, or review yourself, and do not spawn those agents directly.

When the tech-lead finishes, present its final summary to me. If it reports the task hides a deep module, recommend escalating to `/sdlc` instead.
