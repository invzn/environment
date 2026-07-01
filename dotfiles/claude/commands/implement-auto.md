---
description: Full implementation workflow (auto mode) - vertical-slice TDD, runs all phases end-to-end without pausing
argument-hint: <task description>
---
You are acting as a senior tech lead orchestrating a code change using **vertical-slice TDD** in **auto mode**: discovery, planning, TDD loop (one test → one impl → repeat), review. Run all phases end-to-end without pausing for approval.

Read `~/.claude/skills/tdd/SKILL.md` for the methodology before starting — especially the "Anti-Pattern: Horizontal Slices" section. Do NOT batch all tests then all implementation; the language expert runs RED→GREEN→refactor per behavior.

Bash is for read-only commands only here: `git diff`, `git log`, `git show`, `git status`. Do NOT modify files yourself — delegate to expert agents via the Task tool.

Use the Task tool with `subagent_type: "<agent-name>"` to delegate. Run independent agents in parallel by issuing multiple Task calls in a single response.

Task: $ARGUMENTS

## Phase 1: Discovery
1. Read and understand the requirements above.
2. Task → `repo-expert` to identify relevant repos, files, and existing public interfaces.
3. If multiple repos are involved, invoke `repo-expert` once per repo (in parallel).

## Phase 2: Planning
Per the TDD skill's Planning checklist:
1. Note what interface changes are needed.
2. Identify opportunities for **deep modules** (small interface, deep implementation) — see `~/.claude/skills/tdd/language.md`.
3. Design interfaces for **testability** — see `~/.claude/skills/tdd/interface-design.md`.
4. **List the behaviors to test, prioritized — NOT a function-by-function implementation plan.**
5. Identify the **tracer bullet**: the first behavior to drive end-to-end.

## Phase 3: TDD Loop
Delegate to the appropriate language expert (`go-expert`, `python-expert`, or `language-expert`) to run the full RED→GREEN→refactor cycle for the planned behaviors.

The language expert writes BOTH the tests and the implementation, one behavior at a time:
- RED: write a failing test
- GREEN: minimal code to pass
- Refactor (only if green): clean up, deepen modules
- Repeat for the next behavior

Pass the language expert: (a) the prioritized behavior list, (b) the interface sketch, (c) any conventions from discovery.

## Phase 4: Review
1. Task → `reviewer` for general code quality (must flag implementation-detail tests — see `~/.claude/skills/tdd/tests.md`).
2. Task → the appropriate standards reviewer (`go-standards-reviewer` or `python-standards-reviewer`).
3. Optionally invoke specialized reviewers in parallel:
   - `architect-reviewer` — design/structural changes
   - `security-reviewer` — auth, input handling, or API changes
   - `performance-reviewer` — hot paths or data-heavy changes
   - `dx-reviewer` — public APIs or onboarding-related code

## Phase 5: Fix (if reviewers found issues)
1. Task → the appropriate language expert with the review findings to apply fixes.
2. The expert applies fixes test-first when behavior changes; minimal edits when fixes are stylistic.
3. Re-run relevant reviewers to confirm fixes.

## Final Summary
## Summary
- Requirements (one sentence)
- Discovery: key findings from repo-expert
- Plan: tracer bullet + prioritized behaviors
- TDD cycles: per-behavior test+impl summary
- Review results: consolidated findings grouped by severity
- Files changed: `path/to/file` — what changed
- Notes: risks, deferred refactors, follow-ups
