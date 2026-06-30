---
description: "LLM workflow — Stage 5: produce the subagent task list (Full: skeleton first, then one MR per module; Lite: modules in sequence)"
argument-hint: <path to design doc>
---
You are the **lead agent** running **Stage 5 (Planning)** of the LLM development workflow.

**Canonical spec (source of truth):** `~/.claude/references/llm-workflow/LLM_WORKFLOW.md` + `GLOSSARY.md`. Defer to it for anything unstated.

Read the design doc at: $ARGUMENTS

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may edit the design doc (markdown only) — do not touch code.

## Rules
- **1 deep module = 1 task = 1 MR.**
- **Lite tier — skip the skeleton.** No shared interface is committed before validation (single module, or several strictly one-at-a-time), so there is nothing for a skeleton to lock. The plan is the module(s) in sequence, branched from the feature branch holding the doc; a wrong interface is corrected for free by backtracking because nothing else is in flight.
- **Full tier — skeleton first.** Task 0 is the **tracer-bullet skeleton**: all module interfaces + stub implementations + one passing end-to-end test that proves the contracts compose. The design doc and agreed interfaces land in this **base branch**; every module MR branches from it.
  - The skeleton is a **vertical** tracer (one thin path through *all* the stubs), **not** the horizontal "all-interfaces-then-all-code" anti-pattern. No module is implemented.
  - It carries the **second and third interface checks**: its passing end-to-end test is the **automated/empirical** check (contracts *mechanically* compose); its human review is the **interface-lock gate** — the deepest-scrutiny human review in the whole tier. **Do not let it be rubber-stamped** — the review question is *"are these the right interfaces to lock?"*, not *"does this scaffolding look fine?"*
  - **Do not parallelize before the skeleton merges.** An interface change after parallel work starts ripples across every in-flight module.
  - After it merges and interfaces lock, the remaining modules deepen **one MR each, parallelizable** (interface-isolated).
  - **The lock is soft, not one-way.** Backtracking across a locked interface is permitted but costly: pause in-flight modules, revise the interface in the base/skeleton branch, re-merge the skeleton, rebase the in-flight modules onto it.

## Steps
1. Read the **Modules** section and the recorded tier.
2. Define the task list:
   - **Lite:** the module(s) as sequential tasks, branched from the feature branch. No Task 0.
   - **Full:** **Task 0** = the tracer skeleton (which interfaces, which stubs, the end-to-end test proving composition); **Task 1..n** = one per deep module, each deepening a stub into the real implementation. Note dependencies (most independent once the skeleton lands).
3. Append a **## Tasks** section. Each task: the module/scope, the behaviors it must cover, and the branch-from point (skeleton base for Full module tasks).

## Output
- The **Tasks** section: the module task(s) in sequence (Lite), or Task 0 (skeleton) + one task per module (Full)

**Next:**
- **Lite:** `/wf-implement <doc> 1` — build the first module; continue in sequence.
- **Full:** `/wf-implement <doc> 0` to build the skeleton first, then `/wf-implement <doc> <task-n>` per module (only after the skeleton is merged). Batch the MR reviews.
