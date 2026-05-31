# LLM Workflow V2

My development workflow using LLMs.

## Non-negotiables

1. All code must be reviewed by me.
2. All merge requests must be human-readable — **reviewable in one sitting**, not a line-count limit.

---

## Lineage

The macro-shape is **Staged Delivery** (McConnell, *Rapid Development*): do
concept → requirements → architecture **once, up front**, then construct and
deliver in successive usable increments. Stages 1–4 are that up-front phase
(split into three altitudes — behavior, interface, tech); the per-module MRs
are the delivery stages.

Two deliberate grafts make it not pure Staged Delivery:

- **Risk-first sequencing (Boehm's spiral):** MR #0 proves the costliest-to-
  change decision — that the interfaces compose — before any module is
  deepened. Tackle the highest-risk element first, cheaply.
- **Tracer-bullet skeleton (Hunt & Thomas):** MR #0 *is* a walking skeleton —
  all interfaces stubbed, one passing end-to-end test.

And one deliberate departure: **backtracking is allowed.** Staged Delivery
assumes the architecture is frozen after the up-front phase; here any stage may
revise an earlier doc section and re-run forward. That's the agile/iterative
correction — the pipeline is a default order, not one-way gates.

Two named *Rapid Development* best practices are load-bearing: **Lifecycle
Model Selection** (the V1/V2 routing rule, applied per task) and **Designing
for Change** (Ousterhout's deep modules — isolate volatility behind narrow
interfaces). **Miniature Milestones** (each gate, each one-module MR) and
**Inspections** (agent review + standards review + human gate) round it out.

What does *not* transfer: McConnell's central result that **People** dominate
development speed. There's no team here — the binding resource is human review
attention, which is why MRs are sized "reviewable in one sitting."

---

## Tracks

V2 is the **heavy track**: a full upfront design pipeline for work that needs it. The older `implement` / `implement-auto` commands remain as the **fast path** (V1) — not deprecated clutter, but the escape hatch for small, well-scoped changes. Between them sits **V2-lite** (see below) for a single deep module. Depth decides which tier; the routing rule makes that call.

### Routing rule

> **Route on depth, not on whether an interface changed.** Work that introduces one or more **deep modules** (Ousterhout — narrow interface, substantial hidden implementation) goes to V2. Everything else — shallow changes, trivial interface tweaks, behavior behind a stable interface, mechanical refactors *regardless of size* — goes to V1.

The trigger keys off the one thing V2's machinery exists to protect: **deep modules and their interfaces.** Every heavy stage (Abstract Solution, Design, Module, the critique gate, the tracer bullet) is there to get those interfaces and the decomposition right *before* investing in the implementation hidden behind them. A deep module is precisely the thing that (a) has an interface worth designing carefully and (b) hides enough complexity that the implementing agent benefits from the written design doc. Shallow work has neither — a trivial interface and no substantial hidden implementation — so the doc would have no consumer and none of the machinery earns its keep.

"Deep module?" subsumes the old "interface changed?" proxy: a deep module always has an interface worth designing, while a changed interface with nothing substantial behind it (an added param, a rename) does not. Routing on depth also ignores size by construction — a large rewrite with no new depth is still V1.

### Three tiers

Depth decides not just *whether* to go heavy but *how* heavy. The MR #0 / parallel-lock machinery exists only to stop an interface change from rippling across *parallel* work — so it earns its keep only with more than one deep module.

| Tier | When | What runs |
|---|---|---|
| **V1 (fast path)** | No deep module | `/implement`, `/implement-auto`, `/scout-and-plan` |
| **V2-lite** | Exactly one deep module | Stages 1–4 + Implement. **Skip Planning's MR #0 / parallel-lock** — there is nothing to parallelize. |
| **Full V2** | Multiple deep modules | All six stages. MR #0 locks interfaces before parallel deepening. |

- **Who decides:** the main thread assesses "does this introduce a deep module, and how many?" and recommends a tier; I confirm or override. A *smell* of depth from the abstract-solution sketch is enough to route — the full decomposition (stage 4) is not a prerequisite.
- **Escalation:** if a V1 task surfaces a deep module mid-flight, **stop and escalate**, re-entering at Design/Module. If a V2-lite task turns out to need a second deep module, escalate to full V2 (add MR #0).
- **Status: provisional.** This routing rule has zero real runs behind it. Revisit after ~10 uses.

---

## The accreting document

A single design doc grows one section per stage and is the **single source of truth**. It lives **in the target repo on the feature branch** (e.g. `docs/design/<feature>.md`), committed — so it is versioned, travels with the code, is itself reviewable, and survives across sessions.

Backtracking (see [Lineage](#lineage)) happens here: any stage may send you back to revise an earlier section, after which you re-run forward from there.

---

## Stages

Each stage is its own slash command (natural human gates, easy re-entry). An optional orchestrator can run the full chain.

The three middle stages are genuinely distinct **altitudes** of the same problem. The rule that keeps them from collapsing into each other:

> **Behavior decisions live in Design. Interfaces live in Module. Concrete tech lives in Implement.**

Worked example — "add rate limiting":
- *Design* says "limiter state is shared across instances; fail **closed** if the store is unavailable" (behavioral properties, mechanism-agnostic).
- *Module* defines `LimitStore.Take(ctx, key, n) → remaining` with a contract encoding those properties. No tech named.
- *Implement* chooses Redis vs in-memory behind `LimitStore`. The word "Redis" does not appear in the doc before Implement — unless a specific tech is itself a hard requirement.

### 1. Gather Requirements

input: a problem or goal

A conversation with the main thread to align on requirements. Requirements state **what must be true**, mechanism-agnostic — satisfiable many ways.

output: doc with **problem/goal** + **requirements**

### 2. Determine Abstract Solution

input: doc through requirements

A conversation with the main thread to commit to **one mechanism family** that meets the requirements. Test of this stage: if you could swap the answer without touching the requirements, it belongs here.

**Gate: optional.** The stage-3 design agent consumes stages 1–3 as a single artifact, so the pause *here* serves only me. Take it when the mechanism-family choice is contested; otherwise fold this conversation into Design and stop only at the stage-3 handoff gate.

output: + **abstract solution**

### 3. Design Implementation

input: doc through abstract solution

A conversation with the main thread to settle **how it works conceptually** — data flow, key decisions, tradeoffs, and **behavioral properties** (e.g. shared state, fail-open vs fail-closed). Still no interfaces named.

output: + **implementation design**

### 4. Module

input: doc through implementation design

A conversation with the main thread to decompose the design into **deep modules behind narrow interfaces** (Ousterhout — small interface, substantial hidden implementation; *not* architectural layers). Each module's spec encodes the behavioral properties chosen in Design. No concrete tech.

Sizing for reviewability happens here: if a module would produce an MR with more **behaviors** than I can review in one sitting, **split the module**. Module granularity is the lever that keeps MRs human-readable — never split the MR, split the module.

output: + **list of module interfaces and specs**

### 5. Planning

input: doc through module specs

Create the list of subagent tasks. **1 deep module = 1 task = 1 MR.**

**V2-lite skips the MR #0 sequencing below.** With a single deep module there is nothing to parallelize, so the tracer-bullet skeleton and interface-lock exist only to serve full V2 (multiple modules). A single-module plan is just that one task.

Sequencing (full V2):
- **MR #0 is the tracer-bullet skeleton:** all interfaces + stub implementations + a passing end-to-end test that proves the contracts compose. The doc and agreed interfaces land in this base branch; subsequent module MRs branch from it.
- After MR #0 is merged and interfaces are locked, the remaining modules are deepened — **one MR each, parallelizable**, because they are interface-isolated.
- **Do not parallelize before MR #0 is merged.** An interface change after parallel work has started ripples across every in-flight module.

output: + **list of subagent tasks**

### 6. Implement

input: a subagent task

The full per-task cycle (essentially `implement-auto` run once per task):

1. **TDD loop** — red → green → refactor, one behavior at a time.
2. **Agent review + fix** — `reviewer` + standards reviewer (+ optional specialists), findings applied.
3. **Clean MR** opened.
4. **My review** — the human gate. Non-negotiable #1 satisfied by both layers.

Reviews of parallel module MRs are **batched** to keep the human gate from becoming a per-MR bottleneck.

output: a merge request

---

## Gates & feedback

- **Human gates are for me, not the agent.** The design agent consumes the doc *through stage 3* as one artifact — stages 1 and 2 are folded into it. So the pause *boundaries* within 1–3 serve only my ability to catch a mistake early. **Stage 1 (requirements) and stage 3 (design — the agent handoff) are hard gates; the stage-2 gate is optional**, taken only when the mechanism-family choice is contested.
- **Module-interface critique gate:** before Implement, run a critique pass on the design + interfaces (`design-review` / `architect-reviewer`, or a grill). The tracer-bullet skeleton then empirically confirms the contracts compose. Two cheap checks before deep investment — because interface mistakes are the costliest.
- **Backtracking:** any stage may revise an earlier section of the doc in place; re-run forward from there.

---

## Commands

Each stage is a slash command (`wf-` prefix groups the heavy track, distinct from the V1 fast path). They live in `dotfiles/claude/commands/` and install to `~/.claude/commands/`. Stage 1 creates the design doc; stages 2–5 read it and append their section; stage 6 implements one task per invocation.

| Command | Stage | Role |
|---|---|---|
| `/wf <goal>` | — | Orchestrator: routes V1 vs V2, then runs all six stages, pausing at each gate |
| `/wf-requirements <goal>` | 1 | Routing check, then requirements → **creates** `docs/design/<feature>.md` |
| `/wf-solution <doc>` | 2 | Commit to one mechanism family; append |
| `/wf-design <doc>` | 3 | Behavioral properties, data flow, tradeoffs; append |
| `/wf-modules <doc>` | 4 | Deep modules + interfaces; behavior-count split rule; recommends the critique gate |
| `/wf-plan <doc>` | 5 | Task list — MR #0 tracer skeleton, then 1 module = 1 task = 1 MR |
| `/wf-implement <doc> <task>` | 6 | Per task: TDD → agent review → MR → my review |

The **critique gate** between stages 4 and 5 reuses the existing `/design-review` or `/grill-me` commands — not a new `wf-` command.

Fast path (V1, unchanged): `/scout-and-plan`, `/implement`, `/implement-auto`.
