---
description: "LLM workflow — Stage 6: implement one task via TDD, agent-review, and open an MR for my review"
argument-hint: <path to design doc> <task id>
---
You are the **lead agent** running **Stage 6 (Implement)** of the LLM development workflow for a **single task**.

**Canonical spec (source of truth):** `~/.claude/references/llm-workflow/LLM_WORKFLOW.md` + `GLOSSARY.md` (see `GLOSSARY.md#design-red-flags`). Defer to it for anything unstated.

Arguments: `<design doc path> <task id>` — $ARGUMENTS

Read the design doc for context (the module's interface + spec, and the behavioral properties it must satisfy). Read `~/.claude/skills/tdd/SKILL.md` for the methodology — especially the **"Anti-Pattern: Horizontal Slices"** section. One test → one impl → repeat; never batch all tests then all implementation.

Do NOT modify code yourself — delegate to expert agents via the Task tool. Bash is read-only for you (`git diff`, `git log`, `git show`, `git status`).

## This task's place in the sequence
- **Lite (a module task):** branch from the feature branch holding the doc and implement the module. No interface-lock wait — nothing else is in flight; a wrong interface is corrected for free by backtracking. Concrete tech is chosen *here*, behind the interface.
- **Full — task 0 (the tracer skeleton):** implement all interfaces as stubs + the end-to-end test that proves the contracts compose. The design doc lands in this base branch. (This MR's human review is the **interface-lock gate** — flag it for deep scrutiny, not a rubber stamp.)
- **Full — a module task:** branch from the skeleton's base. **Only proceed if the skeleton is merged and interfaces are locked.** Concrete tech (e.g. a shared cache vs. an in-memory map) is chosen *here*, behind the interface — not in the doc.

## Doc is frozen under Full-tier parallel construction
Once the skeleton merges, the design doc is **read-only on module branches** — there is exactly one writable copy. A legitimate refinement is recorded cheaply as a **proposed doc delta** (one sentence in the MR description); the lead agent folds accepted deltas into the base/skeleton branch at merge time. The canonical doc only ever mutates via the base branch — same discipline as an interface change.

## Steps
1. **TDD loop** — Task → the appropriate language expert (`go-expert`, `python-expert`, or `language-expert`) to run RED→GREEN→refactor for this task's behaviors, one at a time. Pass it: the module's interface + spec from the doc, the behavior list, and the project's test conventions.
2. **Agent review + fix:**
   - Task → `reviewer` (read `~/.claude/skills/tdd/tests.md` first — flag implementation-detail tests).
   - Task → the matching standards reviewer (`go-standards-reviewer` / `python-standards-reviewer`). It **explicitly screens for the design red flags from *A Philosophy of Software Design*** (`~/.claude/references/llm-workflow/GLOSSARY.md#design-red-flags`) — the full set checked against the concrete implementation (the interface-altitude flags were already screened at the Stage-4 critique gate).
   - Optionally `architect-reviewer` / `security-reviewer` / `performance-reviewer` / `dx-reviewer` in parallel when the change warrants it.
   - Task → the language expert to apply findings (test-first when behavior changes). Beyond flagging, drive the repairs: **pull complexity downward**, **define errors out of existence**, and **prefer deeper, more general-purpose interfaces.** Re-run reviewers to confirm.
3. **Open the MR** — small, cohesive, reviewable in one sitting. If it isn't, the module was too big: flag that the Module stage should have split it.

## Batching (Full tier)
Sibling module MRs are **interface-isolated off one skeleton** — collect and present them to me **as a batch** so I page the shared interfaces/design into working memory *once* and amortize that context. Batching does **not** merge them into one oversized review: each MR stays its own one-sitting unit, and a batch has an **optimal size** — past my session capacity, split the batch. More is not better.

## Output
## Task <id>
- Behaviors covered, files changed (`path` — what changed)
- Test results (all passing)
- Concrete tech chosen behind the interface, if any
- Review status (agent layer); any **proposed doc delta**
- MR opened — **ready for my review** (the human gate). Batch with sibling module MRs.
