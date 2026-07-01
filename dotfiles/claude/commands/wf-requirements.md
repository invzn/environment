---
description: "LLM workflow — Stage 1: align on requirements and create the feature design doc"
argument-hint: <problem or goal>
---
You are the **lead agent** running **Stage 1 (Gather Requirements)** of the LLM development workflow's heavy track — for work that introduces deep modules.

**Canonical spec (source of truth):** `~/.claude/references/llm-workflow/LLM_WORKFLOW.md` + `GLOSSARY.md` beside it. This command is a thin binding; defer to the spec for anything unstated.

**Routing check first — one clock only here.** The heavy track exists to get deep modules and their interfaces right before investing. Route on **depth, not on whether an interface changed** (provisional rule — revisit after ~10 uses):
- **No deep module** (shallow change, trivial interface tweak like an added parameter or rename, behavior behind a stable interface, mechanical refactor *regardless of size*) → recommend the **fast path** `/implement` and stop.
- **One or more deep modules** (narrow interface, substantial hidden implementation) → proceed with the heavy track.

A *smell* of depth is enough to route. **Do not pick Lite vs. Full now** — that is a second, deferred clock decided at the *exit of Stage 4*, once the interface list is visible. State the fast-vs-heavy recommendation and proceed only on my confirmation.

Note: requirements alignment is driven by **ambiguity, not depth** — even fast-path work may warrant a one-line requirements confirmation. Depth governs the *design pipeline*, not whether we pin down requirements.

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may create and edit the design doc (markdown only) — do not touch code.

Problem or goal: $ARGUMENTS

## Steps
1. Optionally Task → `repo-expert` to ground the problem in the codebase (relevant repos, prior art, constraints, conventions).
2. Converse with me to pin down **requirements** — *what must be true*, **mechanism-agnostic**. A requirement should be satisfiable many ways; if a draft requirement names a mechanism or technology, push back — that belongs in a later stage. *Exception:* a technology that is itself a hard requirement is recorded here as a constraint. Capture functional needs, constraints, non-goals, and acceptance criteria.
3. Create the accreting design doc at `docs/design/<feature-slug>.md` in the target repo on the feature branch, committed (confirm the slug/path with me). Seed it:

```
# <Feature>

## Problem / Goal
...

## Requirements
- ...
```

## Output
- The created doc path
- The **Problem / Goal** and **Requirements** sections

**Gate: hard.** Requirements are where a misunderstanding is cheapest to fix.

**Next:** `/wf-solution docs/design/<feature-slug>.md` — wait for my go-ahead.
