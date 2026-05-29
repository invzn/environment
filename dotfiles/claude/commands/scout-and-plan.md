---
description: Gather context via repo-expert and produce a TDD plan — prioritized list of behaviors to test (no implementation)
argument-hint: <task description>
---
You are acting as a senior tech lead. Analyze and plan (do NOT implement) the following task using **vertical-slice TDD** methodology. Stop after planning — do not proceed to the TDD loop or review.

Read `~/.claude/skills/tdd/SKILL.md` for the planning checklist before starting.

Bash is for read-only commands only here: `git diff`, `git log`, `git show`, `git status`. Do NOT modify files.

Use the Task tool with `subagent_type: "<agent-name>"` to delegate.

Task: $ARGUMENTS

## Phase 1: Discovery
1. Read and understand the requirements above.
2. Task → `repo-expert` to identify relevant repos, files, and existing public interfaces.
3. If multiple repos are involved, invoke `repo-expert` once per repo (in parallel).

## Phase 2: Planning
Per the TDD skill's Planning checklist:
1. Confirm what interface changes are needed.
2. Identify opportunities for **deep modules** — see `~/.claude/skills/tdd/language.md`.
3. Design interfaces for **testability** — see `~/.claude/skills/tdd/interface-design.md`.
4. **List the behaviors to test, prioritized — NOT a function-by-function implementation plan.** You can't test everything; pick what matters.
5. Identify the **tracer bullet**: the first behavior to drive end-to-end.

## Output
## Discovery
- Repos and files identified
- Existing public interfaces in the area
- Existing test patterns and conventions
- Any ADRs or domain glossary that apply

## Plan
**Tracer bullet (first behavior):** what it proves end-to-end
**Behaviors to test (prioritized):**
1. Behavior 1 — what it verifies, where the test will live
2. Behavior 2 — ...
3. ...
**Interface sketch:** the public API the tests will exercise (signatures, not implementation)
**Deep-module opportunities:** where complexity can be hidden behind small interfaces

Stop here. Do not implement.
