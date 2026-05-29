# LLM Workflow V2

My development workflow using LLMs.

## Non-negotiables

1. All code must be reviewed by me.
2. All merge requests must be human-readable — **reviewable in one sitting**, not a line-count limit.

---

## Two tracks

V2 is the **heavy track**: a full upfront design pipeline for work that needs it. It is the go-forward default for substantial work. The older `implement` / `implement-auto` commands remain as the **fast path** (V1) — they are not deprecated clutter, they are the escape hatch for small, well-scoped changes.

### Routing rule

> **New or changed interface → V2. Behavior change behind an interface that already exists and stays fixed → V1.**

The trigger keys off the one thing V2's machinery exists to protect: interfaces. Every heavy stage (Abstract Solution, Design, Module, the critique gate, the tracer bullet) is there to get interfaces and decomposition right *before* investing in implementation behind them. If a task creates or changes no interface, none of that earns its keep.

This subsumes the obvious cases — novel features and multi-module work almost always require new interfaces, so they route to V2 naturally. It deliberately ignores size: a large rewrite *behind a stable interface* has no design risk and belongs on the fast path.

- **Who decides:** the main thread assesses "does this need a new/changed interface?" and recommends a track; I confirm or override.
- **Escalation:** if a V1 task surfaces an interface change mid-flight, **stop and escalate to V2**, re-entering at the Design/Module stage for that interface.

---

## The accreting document

A single design doc grows one section per stage and is the **single source of truth**. It lives **in the target repo on the feature branch** (e.g. `docs/design/<feature>.md`), committed — so it is versioned, travels with the code, is itself reviewable, and survives across sessions.

The pipeline is **not waterfall.** The stages are a default forward order, not one-way gates. Any stage may send you back to revise an earlier section; you then re-run forward from there. Iteration is expected, not an exception.

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

Sequencing:
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
