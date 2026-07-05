---
description: "Complexity-first SDLC — Stage 2: design it twice — ≥2 radically different designs from independent agents; pick the deepest"
argument-hint: <path to design record>
---
You are the **lead agent** running **Stage 2 (Design it twice)** of the complexity-first SDLC.

**Canonical spec (source of truth):** `~/.claude/references/philosophy-sdlc/PHILOSOPHY_SDLC.md` + `DESIGN-RECORD.md` + `GLOSSARY.md#design-it-twice`. Defer to it for anything unstated.

Read the design record at: $ARGUMENTS (§1 must be gated; if not, stop).

Bash is read-only here. You may edit the design record (markdown only) — no code.

## Independence is the binding's one trick
A single context generating "two designs" anchors the second on the first — you get variations, not alternatives. So: **Task → two (or more) `general-purpose` agents in parallel**, each given *only* §1 (owned knowledge, axis of change, budget) plus repo context, each seeded from a different vantage (e.g. one designs around the data, one around the lifecycle or the caller's mental model). Each returns one design:
- a **name** (a design that won't take a name is the *hard-to-pick-name* red flag before a line of code — replace it)
- **abstraction** — one sentence
- **interface sketch** — ≤5 signatures, no bodies
- **hides** — which decisions stay encapsulated
- **depth judgment** — interface size vs functionality provided

## Steps
1. Spawn the independent design agents as above.
2. Apply the **radical-difference test**: if two designs expose the same interface shape, they are variations — one doesn't count; spawn another agent from a different vantage.
3. Judge on **depth** and **information hiding** — not on which is easiest to build. "Easier to build" may be recorded; it may not decide.
4. Fill §2: one `###` subsection per design, then the **verdict** — the chosen design and why it is *deeper* than **each runner-up, by name**. Runners-up are never deleted; they are the evidence design-it-twice happened.

## Output
- §2 filled, verdict written, `Gate (hard):` line awaiting my approval.

**Gate: hard** — this is the design commitment. **The LLM failure this guards:** the model's first design is its most conventional one; without a forced, independent second attempt you ship the obvious shallow decomposition.

**Next:** `/sdlc-interface <record>` — wait for my go-ahead.
