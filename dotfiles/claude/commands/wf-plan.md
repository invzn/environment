---
description: "Workflow V2 — Stage 5: produce the subagent task list (MR #0 tracer, then one MR per module)"
argument-hint: <path to design doc>
---
You are a senior tech lead running **Stage 5 (Planning)** of Workflow V2.

Read the design doc at: $ARGUMENTS

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may edit the design doc (markdown only) — do not touch code.

## Rules
- **1 deep module = 1 task = 1 MR.**
- **V2-lite (single deep module): no MR #0.** With one module there is nothing to parallelize — the plan is that one task, branched from the feature branch holding the doc. The MR #0 / lock rules below apply only to **full V2** (multiple modules).
- **MR #0 is the tracer-bullet skeleton:** all module interfaces + stub implementations + a passing end-to-end test that proves the contracts compose. **The design doc and the agreed interfaces land in this base branch**; every module MR branches from it.
- **Do not parallelize before MR #0 is merged and interfaces are locked.** An interface change after parallel work has started ripples across every in-flight module.
- After MR #0, the remaining modules deepen **one MR each, parallelizable** (interface-isolated).

## Steps
1. Read the **Modules** section and the recorded tier.
2. Define the task list:
   - **V2-lite (one module):** a single task — the module, branched from the feature branch. No Task 0.
   - **Full V2 (multiple modules):**
     - **Task 0 (MR #0):** the tracer skeleton — which interfaces, which stubs, the end-to-end test that proves composition.
     - **Task 1..n:** one per deep module, each deepening a stub into the real implementation. Note dependencies (most should be independent once MR #0 lands).
3. Append a **## Tasks** section. Each task: the module/scope, the behaviors it must cover, and the branch-from point (MR #0 base for full-V2 module tasks).

## Output
- The **Tasks** section: the single task (V2-lite), or Task 0 (tracer) + one task per module (full V2)

**Next:**
- **V2-lite:** `/wf-implement <doc> 1` — build the single module.
- **Full V2:** `/wf-implement <doc> 0` to build the tracer skeleton first, then `/wf-implement <doc> <task-n>` per module (only after MR #0 is merged). Batch the MR reviews.
