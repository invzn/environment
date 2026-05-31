---
description: "Workflow V2 orchestrator — runs the heavy track end to end (requirements → solution → design → modules → plan → implement), pausing at each gate"
argument-hint: <problem or goal>
---
You are a senior tech lead orchestrating **Workflow V2**, the heavy track for work that introduces one or more deep modules. You will run the six stages in order, **pausing after each for my approval** (except the optional stage-2 gate) before proceeding. The stages are a default forward order, **not one-way gates** — if a stage exposes a flaw upstream, backtrack and revise the design doc in place, then re-run forward.

Problem or goal: $ARGUMENTS

## Routing recommendation (do this first)
Assess **depth**: does this introduce one or more **deep modules** (narrow interface, substantial hidden implementation)?
- **No deep module** (shallow change, trivial interface tweak, behavior behind a stable interface, mechanical refactor *regardless of size*) → recommend the **fast path** `/implement` (V1) and stop unless I override.
- **Exactly one deep module** → **V2-lite**: stages 1–4 + Implement, skipping Planning's MR #0 / parallel-lock.
- **Multiple deep modules** → **full V2** below.
A *smell* of depth is enough to route — the full decomposition is Stage 4. State your tier recommendation and wait for my confirmation. (Provisional rule — zero real runs yet.)

## The stages
The accreting design doc lives at `docs/design/<feature-slug>.md` in the target repo. Each stage appends its section. Pause for my review after each **except stage 2**, whose gate is optional (see below).

1. **Requirements** — *what must be true*, mechanism-agnostic. Create the doc. → **hard gate**.
2. **Abstract Solution** — commit to one mechanism family. → **optional gate**: the Stage-3 agent consumes stages 1–3 as one artifact, so pause here only if the mechanism-family choice is contested; otherwise flow into Design.
3. **Design** — behavioral properties, data flow, tradeoffs. *No interfaces, no tech.* → **hard gate** (the agent handoff).
4. **Modules** — deep modules behind narrow interfaces; specs encode Design's behaviors; split modules by **behavior count** to keep MRs reviewable. The module **count fixes the tier**: one → V2-lite, many → full V2. → pause.
   - **Critique gate:** recommend `/design-review` or `/grill-me` on the interfaces before planning. → pause.
5. **Planning** — task list. **Full V2:** **MR #0 tracer skeleton** (all interfaces + stubs + end-to-end test, doc lands here), then **1 module = 1 task = 1 MR**. **V2-lite:** a single task, no MR #0. → pause.
6. **Implement** — per task: TDD → agent review + fix → MR → **my review** (the human gate). **Full V2:** build MR #0 first; **do not parallelize module tasks until MR #0 is merged and interfaces are locked**; batch MR reviews. **V2-lite:** implement the single module directly off the feature branch.

The placement rule holds throughout: **behavior → Design, interface → Module, tech → Implement.**

## How to run
Drive each stage using the corresponding command's logic (`/wf-requirements`, `/wf-solution`, `/wf-design`, `/wf-modules`, `/wf-plan`, `/wf-implement`), delegating to subagents as those commands specify. Present each stage's output, then wait for my go-ahead.

## Final summary
- Requirements (one sentence) and chosen abstract solution
- Modules and their interfaces
- Tasks: MR #0 + per-module MRs, and their review status
- Risks, deferred refactors, follow-ups
