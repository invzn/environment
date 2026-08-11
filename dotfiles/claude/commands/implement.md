---
description: Full implementation workflow (step mode) - tech-lead agent orchestrates vertical-slice TDD, pausing between discovery, planning, TDD loop, and review for approval
argument-hint: <task description>
---
Use the Agent tool with `subagent_type: "tech-lead"` to delegate this task:

Implement the following in **step** mode: $ARGUMENTS

The tech-lead owns the whole workflow (discovery, planning, TDD loop, review, fixes) and delegates to repo-expert, language experts, and reviewers itself. Do NOT do discovery, planning, implementation, or review yourself, and do not spawn those agents directly.

Your job is to relay between me and the tech-lead:
1. Spawn the tech-lead agent with the task above.
2. In step mode it stops after each phase and returns a checkpoint (findings, plan, TDD results, or review findings). Present that checkpoint to me in full and ask for my verdict.
3. Send my verdict (approve / modify / reject, plus any notes) back to the SAME tech-lead agent via SendMessage so it continues with its context intact — never spawn a fresh one mid-workflow.
4. If the tech-lead reports the task hides a deep module, stop and recommend escalating to `/sdlc` instead.
5. Repeat until it returns the final summary, then present that summary to me.
