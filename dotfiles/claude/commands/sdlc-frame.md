---
description: "Complexity-first SDLC — Stage 1: frame the strategic intent (owned knowledge, axis of change, complexity budget) and create the design record"
argument-hint: <problem or goal>
---
You are the **lead agent** running **Stage 1 (Frame the strategic intent)** of the complexity-first SDLC.

**Canonical spec (source of truth):** `~/.claude/references/philosophy-sdlc/PHILOSOPHY_SDLC.md` + `DESIGN-RECORD.md` + `GLOSSARY.md`. Defer to it for anything unstated.

Problem or goal: $ARGUMENTS

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may create/edit the design record (markdown only) — no code. **Do not prompt for or produce code or designs at this stage.**

## Steps
1. Converse with me to settle the three §1 fields:
   - **Owned knowledge** — what this change knows that nothing else may. Noun phrases naming knowledge, 1–3 bullets ("retry policy for upstream fetches", not "handle retries better").
   - **Axis of change** — one sentence: what is likely to change behind the boundary. These two determine where the deep module's boundary falls.
   - **Complexity budget** — what is *allowed to get harder* and what *must stay simple*, each entry naming a module/interface **and who pays**.
2. **Fast-path check**, derived from the fields themselves: if there is genuinely *no knowledge worth hiding* — no boundary to place; purely mechanical or shallow work — say so plainly and recommend `/implement` instead. Stop unless I override.
3. Create the record at `docs/design/<slug>.md` (confirm the slug) from the skeleton in `DESIGN-RECORD.md`. Fill **§1 only**; every later section stays skeleton.
4. If a solution sketch crept into the conversation, park it — it belongs in §2 as one of the alternatives, not here. §1 carries no code and no design.

## Output
- The record created, §1 filled, its `Gate (hard):` line awaiting my approval.

**Gate: hard** — this is the cheapest point to correct a misframing, before any design or code is committed to it. **The LLM failure this guards:** asked to "make it work," the model frames the problem tactically around the immediate symptom and never identifies the knowledge worth hiding.

**Next:** `/sdlc-design <record>` — wait for my go-ahead.
