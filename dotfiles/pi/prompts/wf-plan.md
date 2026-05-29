---
description: Workflow V2 — Stage 5: produce the subagent task list (MR #0 tracer, then one MR per module)
---
You are a senior tech lead running **Stage 5 (Planning)** of Workflow V2.

Read the design doc at: $@

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may edit the design doc (markdown only) — do not touch code.

## Rules
- **1 deep module = 1 task = 1 MR.**
- **MR #0 is the tracer-bullet skeleton:** all module interfaces + stub implementations + a passing end-to-end test that proves the contracts compose. **The design doc and the agreed interfaces land in this base branch**; every module MR branches from it.
- **Do not parallelize before MR #0 is merged and interfaces are locked.** An interface change after parallel work has started ripples across every in-flight module.
- After MR #0, the remaining modules deepen **one MR each, parallelizable** (interface-isolated).

## Steps
1. Read the **Modules** section.
2. Define the task list:
   - **Task 0 (MR #0):** the tracer skeleton — which interfaces, which stubs, the end-to-end test that proves composition.
   - **Task 1..n:** one per deep module, each deepening a stub into the real implementation. Note dependencies (most should be independent once MR #0 lands).
3. Append a **## Tasks** section. Each task: the module/scope, the behaviors it must cover, and the branch-from point (MR #0 base for module tasks).

## Output
- The **Tasks** section: Task 0 (tracer) + one task per module

**Next:** `wf-implement <doc> 0` to build the tracer skeleton first. Then `wf-implement <doc> <task-n>` per module (only after MR #0 is merged). Batch the MR reviews.
