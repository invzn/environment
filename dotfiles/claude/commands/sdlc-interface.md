---
description: "Complexity-first SDLC — Stage 3: specify the interface comment-first; critique-screen the interface-altitude red flags"
argument-hint: <path to design record>
---
You are the **lead agent** running **Stage 3 (Specify the interface)** of the complexity-first SDLC.

**Canonical spec (source of truth):** `~/.claude/references/philosophy-sdlc/PHILOSOPHY_SDLC.md` + `DESIGN-RECORD.md` + `GLOSSARY.md#design-red-flags`. Defer to it for anything unstated.

Read the design record at: $ARGUMENTS (§1–§2 must be gated; if not, stop).

Bash is read-only here. You may edit the design record (markdown only) — **no implementation code exists yet, and none is written here.** That is the point: writing the contract first denies the model the move of writing a plausible interface and an implementation that retroactively makes it look intentional.

## Steps
1. Write the **interface contract** into §3, verbatim as it will ship: the interface comment in the target language, every public signature, the full behavioural contract — what the caller gets, what the module needs, the semantics of every value crossing the boundary.
2. **Errors:** define them out of existence where the semantics allow (clamping, sensible defaults, idempotent operations). Every error that remains gets one sentence justifying why it could not be. No sentence, no error.
3. **Backtrack triggers** — any of these means the abstraction is wrong; go back to `/sdlc-design`, do *not* write the code anyway:
   - the contract needs a paragraph of special cases
   - the module can't be summarized in one sentence
   - a name refuses to settle
4. **Critique screen** — Task → `red-flag-auditor` with §1–§3 only (there is no code to read), screening exactly the five interface-altitude flags: **shallow module, information leakage, overexposure, special-general mixture, pass-through method**. Record `clean` or the finding per flag in §3's critique line — screened, never assumed. For a contract worth extra scrutiny, recommend `/grill-me` on it.
5. Repair findings by revising the contract (or backtracking), then re-screen.

## Output
- §3 filled: contract, error ledger, critique screen, `Gate (critique):` line.

**Gate: critique** — *is this a deep module, or did we just name a shallow one?* **The LLM failure this guards:** a plausible interface retro-fitted by its implementation.

**Next:** `/sdlc-implement <record>` — wait for my go-ahead.
