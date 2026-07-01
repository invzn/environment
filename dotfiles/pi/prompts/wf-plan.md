---
description: Workflow — Stage 5: produce the task list (Full: skeleton first, then one MR per module; Lite: modules in sequence)
---
You are a senior tech lead running **Stage 5 (Planning)** of the heavy track.

Read the design doc at: $@ — including the **tier flag** recorded at Stage 4.

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may edit the design doc (markdown only) — do not touch code.

## Rules
- **1 deep module = 1 task = 1 MR.**
- **Lite tier — skip the skeleton.** No shared interface is committed before validation, so there is nothing for a skeleton to lock. The plan is the module(s) in sequence, branched from the feature branch holding the doc; a wrong interface is corrected for free by backtracking because nothing else is in flight. The skeleton / lock rules below apply only to **Full**.
- **Full tier — the skeleton is the first increment.** It is a **vertical tracer**: all module interfaces + stub implementations + one passing end-to-end test proving the contracts compose — *not* a horizontal "all-interfaces-then-all-code" layer. **The design doc and the agreed interfaces land in this base branch**; every module MR branches from it.
  - The skeleton carries the **second and third interface checks**: its end-to-end test is the *automated* check (the contracts mechanically compose — types line up, the path runs); its human review is the *interface-lock gate* — the highest-leverage human review in the whole track. Stubbing every interface, wiring them, and writing the end-to-end test is real work; none of the three checks is cheap.
  - **Do not parallelize before the skeleton merges and interfaces are locked.** An interface change after parallel work has started ripples across every in-flight module.
  - After the skeleton merges, the remaining modules deepen **one MR each, parallelizable** (interface-isolated).
  - **The lock is soft, not one-way.** Backtracking across a locked interface is permitted but costly: pause the in-flight modules, revise the interface in the base/skeleton branch, re-merge the skeleton, and rebase the in-flight modules onto it.

## Steps
1. Read the **Modules** section and the recorded tier.
2. Define the task list:
   - **Lite:** one task per deep module, in sequence, branched from the feature branch. **No skeleton task.**
   - **Full:**
     - **Task 0 (skeleton):** the tracer — which interfaces, which stubs, the end-to-end test that proves composition.
     - **Task 1..n:** one per deep module, each deepening a stub into the real implementation. Note dependencies (most should be independent once the skeleton lands).
3. Append a **## Tasks** section. Each task: the module/scope, the behaviors it must cover, and the branch-from point (skeleton base for Full module tasks; feature branch for Lite).

## Output
- The **Tasks** section: per-module tasks (Lite), or Task 0 (skeleton) + one task per module (Full)

**Next:**
- **Lite:** `wf-implement <doc> 1` — build the first module; repeat per task in sequence.
- **Full:** `wf-implement <doc> 0` to build the skeleton first, then `wf-implement <doc> <task-n>` per module (only after the skeleton is merged). Batch the MR reviews.
