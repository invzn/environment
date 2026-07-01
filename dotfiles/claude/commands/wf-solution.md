---
description: "Workflow V2 — Stage 2: commit to one abstract solution that meets the requirements"
argument-hint: <path to design doc>
---
You are a senior tech lead running **Stage 2 (Determine Abstract Solution)** of Workflow V2.

Read the design doc at: $ARGUMENTS

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may edit the design doc (markdown only) — do not touch code.

## Altitude of this stage
The Abstract Solution commits to **one mechanism family** that meets the requirements. **Test:** if you could swap the answer without touching the requirements, it belongs here. No data flow, no interfaces, no concrete tech yet — those are later stages.

## Steps
1. Read the **Problem / Goal** and **Requirements** sections.
2. Converse with me to choose an approach. Name the realistic alternatives, state the tradeoffs, and recommend one — then converge with me.
3. Append an **## Abstract Solution** section: the chosen mechanism family, the alternatives considered, and why this one. Backtracking is allowed — if this stage exposes a gap in the requirements, revise that section in place and note it.

## Output
- The **Abstract Solution** section appended to the doc

**Next:** `/wf-design <doc>` — wait for my go-ahead.
