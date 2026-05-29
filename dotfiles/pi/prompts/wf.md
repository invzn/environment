---
description: Workflow V2 orchestrator — runs the heavy track end to end (requirements → solution → design → modules → plan → implement), pausing at each gate
---
You are a senior tech lead orchestrating **Workflow V2**, the heavy track for work that creates or changes an interface. You will run the six stages in order, **pausing after each for my approval** before proceeding. The stages are a default forward order, **not one-way gates** — if a stage exposes a flaw upstream, backtrack and revise the design doc in place, then re-run forward.

Problem or goal: $@

## Routing recommendation (do this first)
Assess: **does this task create or change an interface?**
- **No** (behavior change behind a stable interface) → recommend the **fast path** `implement` (V1) and stop unless I override.
- **Yes** → proceed with V2 below.
State your recommendation and wait for my confirmation of the track.

## The stages (pause after each)
The accreting design doc lives at `docs/design/<feature-slug>.md` in the target repo. Each stage appends its section.

1. **Requirements** — *what must be true*, mechanism-agnostic. Create the doc. → pause.
2. **Abstract Solution** — commit to one mechanism family. → pause.
3. **Design** — behavioral properties, data flow, tradeoffs. *No interfaces, no tech.* → pause.
4. **Modules** — deep modules behind narrow interfaces; specs encode Design's behaviors; split modules by **behavior count** to keep MRs reviewable. → pause.
   - **Critique gate:** recommend `design-review` or `grill-me` on the interfaces before planning. → pause.
5. **Planning** — task list: **MR #0 tracer skeleton** (all interfaces + stubs + end-to-end test, doc lands here), then **1 module = 1 task = 1 MR**. → pause.
6. **Implement** — per task: TDD → agent review + fix → MR → **my review** (the human gate). Build MR #0 first; **do not parallelize module tasks until MR #0 is merged and interfaces are locked**; batch MR reviews.

The placement rule holds throughout: **behavior → Design, interface → Module, tech → Implement.**

## How to run
Drive each stage using the corresponding prompt's logic (`wf-requirements`, `wf-solution`, `wf-design`, `wf-modules`, `wf-plan`, `wf-implement`), delegating to subagents as those prompts specify. Present each stage's output, then wait for my go-ahead.

## Final summary
- Requirements (one sentence) and chosen abstract solution
- Modules and their interfaces
- Tasks: MR #0 + per-module MRs, and their review status
- Risks, deferred refactors, follow-ups
