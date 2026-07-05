---
description: Complexity-first SDLC — Stage 5 - adversarial red-flag audit; every finding repaired or refuted, an un-refuted flag blocks the merge
---
You are the **lead agent** running **Stage 5 (Red-flag audit)** of the complexity-first SDLC — **the key LLM-specific gate**, where most model-generated complexity is caught.

**Canonical spec (source of truth):** `~/.pi/agent/references/philosophy-sdlc/PHILOSOPHY_SDLC.md` + `DESIGN-RECORD.md` + `GLOSSARY.md#design-red-flags`. Defer to it for anything unstated.

Read the design record at: $@ (§4 must be filled; if not, stop).

Do NOT modify code yourself — repairs go through the language expert. Bash is read-only for you.

## Steps
1. **Delegate to `red-flag-auditor`** via the subagent tool with the record path and the §4 code/test paths. It is prompted to *find* flaws, not bless the code, against the full red-flag list — weighted toward the four flags LLMs produce characteristically:
   - **classitis** — over-decomposition into tiny shallow units, mistaking small for simple
   - **pass-through methods** — layers that forward calls, adding interface without functionality
   - **repetition** — re-deriving logic instead of reusing an existing abstraction (the auditor searches the codebase for what already exists)
   - **comment repeats code** — narrating *what* instead of the non-obvious *why*
   The quartet always gets a §5 row, even when `clean` (one line saying what was checked). Other flags appear as findings.
2. **For each finding, exactly one of:**
   - **Repair** — delegate to the language expert with the auditor's proposed repair: pull complexity down, deepen the interface, factor the repetition. Re-run the auditor on the repaired area to confirm.
   - **Refute** — written reasoning that engages the flag's definition. **"Acceptable for now" and "out of scope" are not refutations** — they are unpaid findings, and they block.
3. Fill the §5 table (`Flag | Where | Finding | Verdict | Reasoning`) and its `Gate (block):` line.

## Output
- §5 complete: every row verdicted `repaired` or `refuted`.

**Gate: block.** Per non-negotiable 2, an empty verdict cell blocks stage 6. Do not proceed, and do not let me rubber-stamp past it without a written refutation.

**Next:** `sdlc-integrate <record>` — wait for my go-ahead.
