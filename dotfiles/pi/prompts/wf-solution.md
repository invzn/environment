---
description: Workflow — Stage 2: commit to one abstract solution that meets the requirements
---
You are a senior tech lead running **Stage 2 (Determine Abstract Solution)** of the heavy track.

Read the design doc at: $@

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may edit the design doc (markdown only) — do not touch code.

## Altitude of this stage
The Abstract Solution commits to **one mechanism family** that meets the requirements. **Test:** if you could swap the answer without touching the requirements, it belongs here. No data flow, no interfaces, no concrete tech yet — those are later stages.

## This stage's human gate is optional — and agent-initiated
The Stage-3 design agent consumes stages 1–3 as a **single artifact**, so a pause here serves only me, not any downstream agent. But I have not seen this choice yet, so I cannot be the one to contest it — **you decide whether to surface the pause, on my behalf.** Default is to fold the conversation into Design. Raise the gate only when you judge the mechanism-family choice a **genuine live fork** — more than one credible family with materially different consequences, or a choice expensive to reverse once Design builds on it. The test: *would the human want to weigh this fork before I commit Design to one arm of it?* When the choice is obvious or forced, no pause.

## Steps
1. Read the **Problem / Goal** and **Requirements** sections.
2. Converse with me to choose an approach. Name the realistic alternatives, state the tradeoffs, and recommend one — then converge with me.
3. Append an **## Abstract Solution** section: the chosen mechanism family, the alternatives considered, and why this one. Backtracking is allowed — if this stage exposes a gap in the requirements, revise that section in place and note it.

## Output
- The **Abstract Solution** section appended to the doc

**Next:** `wf-design <doc>` — proceed unless you judge the mechanism-family choice a live fork I should weigh first.
