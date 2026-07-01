---
description: Full implementation workflow (step mode) - vertical-slice TDD, pauses between discovery, planning, TDD loop, and review for approval
argument-hint: <task description>
---
You are acting as a senior tech lead orchestrating a code change using **vertical-slice TDD** in **step mode**: discovery, planning, TDD loop (one test → one impl → repeat), review. Pause after each phase, present your output, and wait for my explicit approval before proceeding.

Read `~/.claude/skills/tdd/SKILL.md` for the methodology before starting — especially the "Anti-Pattern: Horizontal Slices" section. Do NOT batch all tests then all implementation; the language expert runs RED→GREEN→refactor per behavior.

Bash is for read-only commands only here: `git diff`, `git log`, `git show`, `git status`. Do NOT modify files yourself — delegate to expert agents via the Task tool.

Use the Task tool with `subagent_type: "<agent-name>"` to delegate. Run independent agents in parallel by issuing multiple Task calls in a single response.

This is the **fast path** of the LLM development workflow — for work with **no deep module** (canonical spec: `~/.claude/references/llm-workflow/LLM_WORKFLOW.md`). If discovery reveals the task actually hides a deep module, **stop and escalate** to the heavy track (`/wf` at Design/Module) rather than pushing it through here.

Task: $ARGUMENTS

## Phase 1: Discovery
1. Read and understand the requirements above. **If the requirement is ambiguous** (not whether it is deep — ambiguity, not depth, is the trigger), pause for a one-line requirements confirmation before any TDD.
2. Task → `repo-expert` to identify relevant repos, files, and existing public interfaces.
3. If multiple repos are involved, invoke `repo-expert` once per repo (in parallel).

**Present:**
## Discovery
- Repos and files identified
- Existing public interfaces in the area
- Existing test patterns and conventions
- Any ADRs or domain glossary that apply

**Proceed to planning?** — wait for approval.

## Phase 2: Planning
Per the TDD skill's Planning checklist:
1. Confirm what interface changes are needed.
2. Identify opportunities for **deep modules** (small interface, deep implementation) — see `~/.claude/skills/tdd/language.md`.
3. Design interfaces for **testability** — see `~/.claude/skills/tdd/interface-design.md`.
4. **List the behaviors to test, prioritized — NOT a function-by-function implementation plan.** You can't test everything; pick what matters.
5. Identify the **tracer bullet**: the first behavior to drive end-to-end.
6. **Keep the work reviewable in one sitting.** The fast path has no module to split, so:
   - *Mechanical work* (renames, reformats, dependency bumps, large mechanical rewrites) counts as one unit of comprehension **only when a machine — not the human — guarantees it changed only what it should** (type checker, green suite, deterministic AST refactor). With no such guarantee the exemption is void: split it or verify independently.
   - *Heavy-but-shallow behavioral work* (substantial new logic behind a stable interface) gets no exemption — **split it into multiple sequential MRs by behavior-cluster in dependency order**, each one comprehensible cluster depending only on already-merged behavior. If it won't cut cleanly, **don't fabricate a cut — take the larger MR and flag it.**

**Present:**
## Plan
**Tracer bullet (first behavior):** what it proves end-to-end
**Behaviors to test (prioritized):**
1. Behavior 1 — what it verifies, where the test lives
2. Behavior 2 — ...
3. ...
**Interface sketch:** the public API the tests will exercise (signatures, not implementation)

**Proceed to TDD loop?** — wait for approval.

## Phase 3: TDD Loop
Delegate to the appropriate language expert (`go-expert`, `python-expert`, or `language-expert`) to run the full RED→GREEN→refactor cycle for the planned behaviors.

The language expert writes BOTH the tests and the implementation, one behavior at a time:
- RED: write a failing test
- GREEN: minimal code to pass
- Refactor (only if green): clean up, deepen modules
- Repeat for the next behavior

Pass the language expert: (a) the prioritized behavior list, (b) the interface sketch, (c) any conventions from discovery (test framework, naming, fixtures).

**Present:**
## TDD Cycles
For each behavior:
- Behavior, test file, implementation file, refactor notes
## Final Test Results
All tests passing.
## Files Changed
- `path/to/file` — what changed

**Proceed to review?** — wait for approval.

## Phase 4: Review
1. Task → `reviewer` for general code quality (read `~/.claude/skills/tdd/tests.md` first — flag implementation-detail tests).
2. Task → the appropriate standards reviewer (`go-standards-reviewer` or `python-standards-reviewer`).
3. Optionally invoke specialized reviewers in parallel:
   - `architect-reviewer` — design/structural changes
   - `security-reviewer` — auth, input handling, or API changes
   - `performance-reviewer` — hot paths or data-heavy changes
   - `dx-reviewer` — public APIs or onboarding-related code

**Present:**
## Review Results
Findings grouped by severity (must fix / should fix / consider).

**Apply fixes?** — wait for approval.

## Phase 5: Fix (if approved)
1. Task → the appropriate language expert with the review findings to apply fixes.
2. The expert applies fixes test-first when behavior changes; minimal edits when fixes are stylistic.
3. Re-run relevant reviewers to confirm fixes.

## Final Summary
## Summary
- Requirements (one sentence)
- Tracer bullet and subsequent behaviors covered
- Files changed
- Review status
- Anything I should know — risks, deferred refactors, follow-ups
