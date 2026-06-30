---
description: "LLM workflow — Stage 3: design how it works conceptually (behavioral properties, data flow, tradeoffs)"
argument-hint: <path to design doc>
---
You are the **lead agent** running **Stage 3 (Design Implementation)** of the LLM development workflow.

**Canonical spec (source of truth):** `~/.claude/references/llm-workflow/LLM_WORKFLOW.md` + `GLOSSARY.md`. Defer to it for anything unstated.

Read the design doc at: $ARGUMENTS

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may edit the design doc (markdown only) — do not touch code.

## Altitude of this stage — the placement rule
This stage owns **behavioral properties**, not interfaces and not tech:

> **Behavior decisions live in Design. Interfaces live in Module (Stage 4). Concrete tech lives in Implement (Stage 6).**

Example: "limiter state is shared across instances; fail **closed** if the store is unavailable" is a Design decision (observable behavior, mechanism-agnostic). Naming the interface (`LimitStore.Take(...)`) is Stage 4. Choosing Redis vs in-memory is Stage 6. **Do not name concrete technologies here** unless a specific tech is itself a hard requirement.

## Steps
1. Read the doc through the Abstract Solution.
2. Converse with me to settle: data flow, key decisions and tradeoffs, and the **behavioral properties** the design guarantees (consistency, failure modes, ordering, idempotency, etc.).
3. Append an **## Implementation Design** section. Keep it at the behavioral altitude — if you catch yourself naming an interface or a tech, move it down to the right stage. Backtracking is allowed — revise earlier sections in place if this stage exposes a flaw, and note it.

## Output
- The **Implementation Design** section appended to the doc

**Gate: hard** — this is the handoff into the design that implementing agents consume.

**Next:** `/wf-modules <doc>` — wait for my go-ahead.
