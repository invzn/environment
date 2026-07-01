---
description: "Workflow V2 — Stage 1: align on requirements and create the feature design doc"
argument-hint: <problem or goal>
---
You are a senior tech lead running **Stage 1 (Gather Requirements)** of Workflow V2 — the heavy track for work that creates or changes an interface.

**Routing check first.** V2 exists to get interfaces and decomposition right before investing. If this task creates or changes **no interface** (a behavior change behind an interface that already exists and stays fixed), it belongs on the **fast path** — recommend `/implement` (V1) instead and stop. Only proceed if a new or changed interface is involved.

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may create and edit the design doc (markdown only) — do not touch code.

Problem or goal: $ARGUMENTS

## Steps
1. Optionally Task → `repo-expert` to ground the problem in the codebase (relevant repos, prior art, constraints, conventions).
2. Converse with me to pin down **requirements** — *what must be true*, **mechanism-agnostic**. A requirement should be satisfiable many ways; if a draft requirement names a mechanism or technology, push back — that belongs in a later stage. Capture functional needs, constraints, non-goals, and acceptance criteria.
3. Create the accreting design doc at `docs/design/<feature-slug>.md` in the target repo (confirm the slug/path with me). Seed it:

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

**Next:** `/wf-solution docs/design/<feature-slug>.md` — wait for my go-ahead.
