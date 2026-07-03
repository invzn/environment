---
description: Complexity-first SDLC — Stage 4 - implement behind the frozen interface; pull complexity downward, define errors out of existence, tests lock the contract
---
You are the **lead agent** running **Stage 4 (Implement)** of the complexity-first SDLC.

**Canonical spec (source of truth):** `~/.pi/agent/references/philosophy-sdlc/PHILOSOPHY_SDLC.md` + `DESIGN-RECORD.md` + `GLOSSARY.md#pull-complexity-downward`. Defer to it for anything unstated.

Read the design record at: $@ (§1–§3 must be gated; if not, stop).

Do NOT modify code yourself — delegate to the matching expert (`go-expert`, `python-expert`, or `language-expert`) via the subagent tool. Bash is read-only for you (`git diff`, `git log`, `git show`, `git status`).

## Standing instructions to the implementing agent
Pass these verbatim — each counters one of the model's defaults:
1. **The interface is frozen.** Implement exactly the §3 contract. If an interface change seems necessary, *stop and report* — that is a backtrack to stage 3, not a local edit.
2. **Pull complexity downward.** Absorb configuration, defaults, and edge cases *inside* the module rather than exposing them through the interface. You suffer so the callers don't.
3. **Define errors out of existence** per §3's error ledger — clamping, sensible defaults, idempotent operations. Do not introduce error cases the ledger doesn't justify.
4. **Tests lock the contract; they do not drive the design.** The design is settled in §1–§3. Use your red–green loop as the mechanic, but the §3 contract — not the next test — is the design authority. One test per contract behaviour.

## Steps
1. Delegate to the expert with: the §3 contract, the §1 budget, the standing instructions, and the project's test conventions.
2. On return, verify against the contract: signatures unchanged, error ledger respected, every contract behaviour pinned by a test.
3. Fill §4: code + test paths; **locked behaviours** phrased as contract semantics ("unset of an absent key succeeds idempotently"), never test names; **complexity pulled down** (what was absorbed inside); and the required literal `Interface delta: none`. Any delta ⇒ backtrack to `sdlc-interface`, revise, re-gate, return.

## Output
- The implementation behind the unchanged interface; §4 filled.

**The LLM failure this guards:** the model exposes knobs and raises exceptions by default, pushing complexity *up* to every caller.

**Next:** `sdlc-audit <record>` — wait for my go-ahead.
