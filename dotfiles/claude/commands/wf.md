---
description: "LLM workflow orchestrator — runs the heavy track end to end (requirements → solution → design → modules → plan → implement), routing by depth and pausing at each gate"
argument-hint: <problem or goal>
---
You are the **lead agent** orchestrating the heavy track of the LLM development workflow. You run the design pipeline and delivery stages in order, **pausing at each human gate** before proceeding. The stages are a default forward order, **not one-way gates** — if a stage exposes a flaw upstream, backtrack and revise the design doc in place, then re-run forward.

**Canonical spec — read it first and treat it as the source of truth:**
`~/.claude/references/llm-workflow/LLM_WORKFLOW.md` (and `GLOSSARY.md` beside it). This command is a thin binding; for anything not spelled out here, defer to the spec. Bash is read-only here (`git diff`, `git log`, `git show`, `git status`); you may create/edit the markdown design doc but not code (the stage commands delegate code to expert agents).

Problem or goal: $ARGUMENTS

## Routing — first clock: fast vs. heavy (do this first)
Route on **depth, not on whether an interface changed.** A cheap smell, made up front:

> **Does this introduce one or more *deep modules* — a narrow interface hiding substantial implementation?**

- **No deep module** → **fast path.** Recommend `/implement` (a lightweight TDD → agent review → MR → human review cycle, no design pipeline). Trivial interface tweaks (an added parameter, a rename), behavior behind a stable interface, and mechanical refactors *regardless of size* are all fast-path. Stop unless I override. *(If the requirement itself is ambiguous, suggest a one-line requirements confirmation before TDD — ambiguity, not depth, triggers that.)*
- **One or more deep modules** → **heavy track**, below.

State your recommendation and wait for my confirmation of the track. (Routing rule is **provisional** — revisit after ~10 uses.)

## The stages (pause after each)
The accreting design doc is the single source of truth. It lives **in the target repo on the feature branch, committed** (default `docs/design/<feature-slug>.md`; confirm the slug). Each stage appends one section. Stages 1–4 are **identical for Lite and Full** — the second routing clock fires at the *end* of stage 4.

1. **Requirements** — *what must be true*, mechanism-agnostic. Create the doc. **Hard gate.** → pause.
2. **Abstract Solution** — commit to one mechanism family. **Optional, agent-initiated gate** — surface it only when the mechanism-family choice is a genuine live fork; otherwise fold into Design. → pause only if surfaced.
3. **Design** — behavioral properties, data flow, tradeoffs. *No interfaces, no tech.* **Hard gate** (the handoff into what implementing agents consume). → pause.
4. **Modules** — deep modules behind narrow interfaces; specs encode Design's behaviors; **split the module (never the MR)** when a module's MR would carry more behaviors than I can review in one sitting — but **depth wins**: if the only split yields shallow modules, take the larger MR and flag it. **Critique gate** (analytical — *are these the right interfaces?*): recommend `/design-review` or `/grill-me` on the interfaces. → pause.

### Routing — second clock: Lite vs. Full (at stage-4 exit)
Now you are looking at the interface list, so the call is near-free. The skeleton/interface-lock machinery exists to prevent **interface drift between independently-built modules** — multiple modules committing to *shared* interfaces before those interfaces are validated. The trigger is **not raw module count.**

- **Lite** — no shared interfaces are committed before validation (a single deep module, *or several built strictly one-at-a-time*). **Skip the skeleton** — a wrong interface is corrected for free by backtracking, since nothing else is in flight.
- **Full** — multiple deep modules will commit to shared interfaces before validation (the usual case when built concurrently). **Skeleton first** to lock interfaces before the modules are deepened against them.

Recommend the tier; I confirm or override. Set the flag, then continue.

5. **Planning** — task list: **1 deep module = 1 task = 1 MR.**
   - **Full:** Task 0 is the **tracer-bullet skeleton** — all interfaces + stubs + one passing end-to-end test proving the contracts compose; the doc and agreed interfaces land in this base branch. Then 1 module = 1 task = 1 MR, parallelizable *after* the skeleton merges.
   - **Lite:** **skip the skeleton** — the module(s) in sequence.
   → pause.
6. **Implement** — per task: TDD (one behavior at a time) → agent review + fix → clean MR → **my review** (the human gate). Full: build the skeleton first; **do not parallelize module tasks until it is merged and interfaces are locked**; under parallel construction the doc is **frozen** (canonical edits go through the base/skeleton branch; a module records a refinement as a one-sentence *proposed doc delta* in its MR). **Batch** sibling MR reviews into one-sitting-sized batches.

The placement rule holds throughout: **behavior → Design, interface → Module, tech → Implement** (tech may also appear at stage 1 only if it is itself a hard requirement).

## Escalation (mid-flight)
- Fast-path work that **turns out to hide a deep module** → stop, re-enter the heavy track at Design/Module.
- A **Lite** task in Implement that surfaces a second deep module sharing interfaces with the first → stop and **escalate to Full**, adding the skeleton before the shared interfaces are committed by both.

## How to run
Drive each stage using its command's logic (`/wf-requirements`, `/wf-solution`, `/wf-design`, `/wf-modules`, `/wf-plan`, `/wf-implement`), delegating to subagents as those commands specify. Present each stage's output, then wait for my go-ahead.

## Final summary
- Track + tier (fast / lite / full) and why
- Requirements (one sentence) and chosen abstract solution
- Modules and their interfaces
- Tasks: skeleton (Full only) + per-module MRs, and their review status
- Risks, deferred refactors, follow-ups
