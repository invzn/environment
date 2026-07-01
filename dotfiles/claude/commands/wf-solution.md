---
description: "LLM workflow — Stage 2: commit to one abstract solution that meets the requirements"
argument-hint: <path to design doc>
---
You are the **lead agent** running **Stage 2 (Determine Abstract Solution)** of the LLM development workflow.

**Canonical spec (source of truth):** `~/.claude/references/llm-workflow/LLM_WORKFLOW.md` + `GLOSSARY.md`. Defer to it for anything unstated.

Read the design doc at: $ARGUMENTS

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may edit the design doc (markdown only) — do not touch code.

## Altitude of this stage
The Abstract Solution commits to **one mechanism family** that meets the requirements. **Test:** if you could swap the answer without touching the requirements, it belongs here. No data flow, no interfaces, no concrete tech yet — those are later stages.

## This stage's human gate is optional and agent-initiated
The Stage-3 design agent consumes stages 1–3 as a **single artifact**, so the pause here serves only me — and I have not seen this choice yet, so I cannot be the one to "contest" it. **You (the lead agent) decide whether to surface the pause**, on my behalf. Default: fold the conversation into Design and flow straight into `/wf-design`. Raise the gate only when the mechanism-family choice is a **genuine live fork** — more than one credible family with materially different consequences, or a choice expensive to reverse once Design builds on it. The test: *would I want to weigh this fork before Design commits to one arm of it?*

## Steps
1. Read the **Problem / Goal** and **Requirements** sections.
2. Converse with me to choose an approach. Name the realistic alternatives, state the tradeoffs, and recommend one — then converge.
3. Append an **## Abstract Solution** section: the chosen mechanism family, the alternatives considered, and why this one. Backtracking is allowed — if this stage exposes a gap in the requirements, revise that section in place and note it.

## Output
- The **Abstract Solution** section appended to the doc

**Next:** `/wf-design <doc>` — proceed unless you judged the mechanism-family choice a live fork worth my review first.
