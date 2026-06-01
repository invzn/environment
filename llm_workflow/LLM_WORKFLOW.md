# An Agent-Agnostic LLM Development Workflow

A high-level workflow for building software with LLM agents. It describes
*what* happens and *why* — the stages, the gates, the routing decision, and the
single artifact that ties them together — without binding to any particular
agent harness, command set, or tool. Concrete tooling (slash commands, named
subagents, file layouts) is an implementation detail left to whoever adopts
this; the shape below is the contract.

## Roles

The workflow assumes four roles. They are logical, not tool-specific — one
person or one agent may play several.

- **The human** — the author and final reviewer. The workflow exists to spend
  this person's attention well.
- **The lead agent** — the orchestrating conversation that talks with the
  human, drives the stages, and writes the design doc.
- **An implementing agent** — does one task: writes the tests and the code for
  a single module via TDD.
- **A reviewing agent** — critiques design, interfaces, code quality, or
  adherence to standards. May be several specialists.

---

## Non-negotiables

1. **All code is reviewed by the human.**
2. **Every merge request is human-readable — reviewable in one sitting.** This
   is a comprehension limit, not a line-count limit.

These two rules drive almost every other decision below. In particular: the
binding resource is *human review attention*, so the unit of delivery is sized
to what a person can absorb at once.

---

## Why it is shaped this way

The macro-shape is **Staged Delivery**: do concept → requirements →
architecture **once, up front**, then construct and deliver the system in
successive usable increments. The up-front phase is the design pipeline
(stages 1–4 below, split into three altitudes); the per-module increments are
the delivery stages (one module, one merge request).

Three deliberate modifications make it more than pure Staged Delivery:

- **Risk-first sequencing (Boehm's spiral).** The first increment proves the
  costliest-to-change decision — *that the interfaces compose* — before any
  module is built out. Tackle the highest-risk element first, cheaply.
- **Tracer-bullet / walking skeleton.** That first increment *is* a walking
  skeleton: every interface stubbed, wired end to end, with one passing test
  proving the path works.
- **Backtracking is allowed.** Pure Staged Delivery freezes the architecture
  after the up-front phase. Here, any stage may send you back to revise an
  earlier section of the design doc, after which you re-run forward from there.
  The pipeline is a *default order*, not a set of one-way gates.

Two further practices are load-bearing — they *generate* the structure.
**Lifecycle-model selection** (pick the right amount of process per task) is
the routing rule itself; **designing for change** (isolate what is likely to
change behind narrow interfaces) is why deep modules exist and why depth is the
thing the router keys on. Two more *protect* that structure rather than
generate it. **Miniature milestones** (each one-module increment) keep delivery
small, frequent, and binary — done or not-done, no silent drift; **inspections**
(each gate — agent review + standards review + the human gate) remove defects
through layered review before the expensive human pass. The first pair decides
what the workflow *is*; the second pair keeps it honest.

> The classic result that *people* dominate development speed does **not**
> transfer cleanly here — there is no team. The binding resource is the
> human's review attention, which is why increments are sized "reviewable in
> one sitting."

---

## Routing: how much process does this task need?

Not every task earns the full pipeline. The router keys off the one thing the
heavy machinery exists to protect: **deep modules and their interfaces.**

> **Route on depth, not on whether an interface changed.** Work that
> introduces one or more **deep modules** — a narrow interface hiding
> substantial implementation — takes the heavy track. Everything else —
> shallow changes, trivial interface tweaks (an added parameter, a rename),
> behavior behind a stable interface, mechanical refactors *regardless of
> size* — takes the fast path.

The rationale: every heavy stage exists to get interfaces and decomposition
right *before* investing in the implementation hidden behind them. A deep
module is precisely the thing that (a) has an interface worth designing
carefully and (b) hides enough complexity that the implementing agent benefits
from a written design. Shallow work has neither, so the design doc would have
no consumer and the machinery earns nothing. Routing on depth also ignores
size by construction: a large rewrite that introduces no new depth is still
fast-path.

**Depth and ambiguity are orthogonal.** Routing on depth governs the *design
pipeline* — the interface and decomposition machinery, whose consumer is the
implementing agent. It does **not** govern requirements alignment, whose
consumer is the human and whose value is catching a misunderstanding at the
cheapest point (stage 1 is a hard gate for exactly this reason). "Shallow to
build" and "clearly specified" are independent axes — a one-parameter change
can still rest on a badly misunderstood requirement. So a *lightweight
requirements check* is available regardless of track, triggered by **ambiguity,
not depth**: the fast path may pause for a one-line requirements confirmation
before TDD without pulling in the heavy machinery.

### Three tiers

Depth decides not just *whether* to go heavy but *how* heavy. The
skeleton-first / interface-lock machinery exists only to stop an interface
change from rippling across *parallel* work — so it earns its keep only when
there is more than one deep module to build in parallel.

| Tier | When | What runs |
|---|---|---|
| **Fast path** | No deep module | A lightweight implement cycle: TDD → agent review → merge request → human review. No up-front design pipeline. |
| **Lite** | Exactly one deep module | The full design pipeline (stages 1–4) + Implement. **Skip the skeleton / interface-lock** — there is nothing to parallelize. |
| **Full** | Multiple deep modules | All six stages. The skeleton increment locks interfaces before the modules are deepened in parallel. |

- **Who decides:** the lead agent assesses "does this introduce a deep module,
  and how many?" and recommends a tier; the human confirms or overrides. This
  runs on a *cheap, up-front depth smell* — a back-of-envelope judgement made
  for every task before any stage — **not** the committed stage-2 abstract
  solution (which only the heavy track produces, so keying on it would be
  circular). The smell is deliberately allowed to be wrong: the initial route is
  a provisional guess, and **escalation is the correction**, not a failure.
- **Escalation is allowed mid-flight.** If a fast-path task surfaces a deep
  module, stop and escalate, re-entering at Design/Module. If a Lite task turns
  out to need a second deep module, escalate to Full (add the skeleton
  increment).
- **Reviewability on the fast path.** The fast path has no Module stage, so it
  cannot use module-splitting to stay reviewable. Two cases: *mechanical* work
  (renames, reformats, dependency bumps, large mechanical rewrites) stays
  reviewable in one sitting by the **comprehension-not-line-count** rule — a
  200-file rename is huge in lines but ~one unit of comprehension; *heavy-but-
  shallow behavioral* work (substantial new logic behind a stable interface)
  gets no such exemption and is kept reviewable by **splitting it into multiple
  sequential merge requests**. "Split the module, never the MR" is a heavy-track
  rule; the fast path splits the MR because it has no module to split.
- **Status: provisional.** This routing rule has zero real runs behind it.
  Revisit after ~10 uses.

---

## The accreting document

A single design doc is the **single source of truth**. It grows **one section
per stage** and lives **in the target repository, on the feature branch**,
committed — so it is versioned, travels with the code, is itself reviewable,
and survives across sessions.

Backtracking happens here: any stage may revise an earlier section in place,
after which you re-run forward from that point.

---

## The three altitudes

The middle stages (Design, Module, Implement) are genuinely distinct
*altitudes* of the same problem. One rule keeps them from collapsing into each
other:

> **Behavioral decisions live in Design. Interfaces live in Module. Concrete
> technology lives in Implement.**

Worked example — *"add rate limiting"*:

- **Design** says: limiter state is shared across instances; fail **closed** if
  the store is unavailable. (Behavioral properties, mechanism-agnostic.)
- **Module** defines `LimitStore.Take(ctx, key, n) → remaining` with a contract
  encoding those properties. No technology named.
- **Implement** chooses the backing store (e.g. an in-memory map vs. a shared
  cache) behind `LimitStore`. A specific technology does not appear in the doc
  before Implement — *unless that technology is itself a hard requirement, in
  which case it is recorded at stage 1 (Requirements) as a constraint.* So tech
  may legitimately appear at stage 1 or stage 6, never stages 2–5.

---

## Stages

Each stage is a discrete step with a natural human gate and easy re-entry. An
optional orchestrator can run the whole chain, pausing at each gate.

### 1. Gather Requirements

- **In:** a problem or goal.
- **Do:** align on requirements. Requirements state **what must be true**,
  mechanism-agnostic — satisfiable many ways.
- **Out:** doc with **problem/goal** + **requirements**.
- **Gate: hard.** Requirements are where a misunderstanding is cheapest to fix.

### 2. Determine Abstract Solution

- **In:** doc through requirements.
- **Do:** commit to **one mechanism family** that meets the requirements. Test
  of this stage: if you could swap the answer without touching the
  requirements, the choice belongs here.
- **Out:** + **abstract solution**.
- **Gate: optional.** The Design stage consumes stages 1–3 as a single
  artifact, so pausing here serves only the human. Take the pause when the
  mechanism-family choice is contested; otherwise fold this conversation into
  Design.

### 3. Design Implementation

- **In:** doc through abstract solution.
- **Do:** settle **how it works conceptually** — data flow, key decisions,
  tradeoffs, and **behavioral properties** (e.g. shared vs. local state,
  fail-open vs. fail-closed). Still no interfaces named.
- **Out:** + **implementation design**.
- **Gate: hard.** This is the handoff into the design that implementing agents
  will consume.

### 4. Module

- **In:** doc through implementation design.
- **Do:** decompose the design into **deep modules behind narrow interfaces**
  (narrow interface, substantial hidden implementation — *not* architectural
  layers). Each module's spec encodes the behavioral properties chosen in
  Design. No concrete technology.
- **Sizing rule:** if a module would produce a merge request with more
  *behaviors* than the human can review in one sitting, **split the module.**
  Module granularity is the lever that keeps merge requests human-readable —
  never split the merge request, split the module. **Splitting is cheap only
  when a natural internal sub-abstraction exists**, so each half stays deep;
  prefer that seam. If the only available split would expose an artificial
  interface and produce *shallow* modules, the module is irreducible: **depth
  wins** — accept the larger merge request and flag it as the rare exception,
  rather than fabricating a seam to hit a size target.
- **Out:** + **list of module interfaces and specs**.
- **Gate: critique.** Before any code, run a critique pass on the design and
  interfaces (an architecture/design review, or an adversarial grilling). The
  skeleton increment then *empirically* confirms the contracts compose. Two
  cheap checks before deep investment — because interface mistakes are the
  costliest to undo.

### 5. Planning

- **In:** doc through module specs.
- **Do:** create the list of implementation tasks. **One deep module = one
  task = one merge request.**
- **Sequencing (Full tier only):**
  - The first increment is the **skeleton**: all interfaces + stub
    implementations + one passing end-to-end test proving the contracts
    compose. The design doc and agreed interfaces land in this base branch;
    every subsequent module branches from it.
  - After the skeleton merges and interfaces are locked, the remaining modules
    are deepened — **one merge request each, parallelizable**, because they are
    interface-isolated.
  - **Do not parallelize before the skeleton merges.** An interface change
    after parallel work has started ripples across every in-flight module.
  - **The lock is soft, not one-way.** Backtracking across a locked interface
    is still permitted — it is the expensive exception the skeleton and critique
    gate exist to make *rare*, not impossible. Recovery: pause the in-flight
    modules, revise the interface in the base/skeleton branch, re-merge the
    skeleton, and rebase the in-flight modules onto it.
- **Lite tier:** skip the skeleton — with a single module there is nothing to
  parallelize. The plan is just that one task.
- **Out:** + **list of tasks**.

### 6. Implement

- **In:** one task.
- **Do:** the per-task cycle:
  1. **TDD loop** — red → green → refactor, **one behavior at a time.** (Not
     all-tests-then-all-code; that horizontal split is an anti-pattern.)
  2. **Agent review + fix** — a code-review agent and a standards-review agent
     (plus optional specialists); findings applied.
  3. **Clean merge request** opened.
  4. **Human review** — the final gate.
- **Out:** a merge request.
- Reviews of parallel module merge requests are **batched** — collected and
  reviewed together so the human gate does not become a per-merge-request
  bottleneck. Batching removes per-MR round-trip latency; it does **not** merge
  them into one oversized review. Each merge request remains its own one-sitting
  unit (interface-isolation is what makes this legitimate), and batching does
  not expand how much a human can absorb well in a sitting.

---

## Gates & feedback

- **Human gates exist for the human, not the agent.** The Design stage consumes
  the doc *through stage 3* as one artifact, so the pause boundaries within
  stages 1–3 serve only the human's ability to catch a mistake early.
  **Requirements (1) and Design (3) are hard gates; the Abstract-Solution (2)
  gate is optional**, taken only when the mechanism-family choice is contested.
- **The critique gate** (between Module and Planning) plus the **skeleton
  increment** are two cheap checks on the interfaces before deep investment.
- **Backtracking:** any stage may revise an earlier section of the doc in
  place; re-run forward from there. Backtracking across an interface already
  locked by a merged skeleton is permitted but costly — see the soft-lock
  recovery under Planning.

---

## At a glance

```
problem
  │
  ▼  route on depth ───────────────► no deep module ─► FAST PATH (implement cycle)
  │
  │  one or more deep modules
  ▼
[1] Requirements   (what must be true)            ── hard gate
[2] Abstract Solution  (one mechanism family)     ── optional gate
[3] Design   (behavioral properties, data flow)   ── hard gate
[4] Module   (deep modules, narrow interfaces)    ── critique gate
[5] Planning   (1 module = 1 task = 1 MR; skeleton first if Full)
[6] Implement   (TDD → agent review → MR → human review)   ── per task
  ▲
  └── any stage may backtrack and re-run forward
```

---

## Glossary

Terminology — *deep* / *shallow module*, *interface*, *Staged Delivery*,
*tracer bullet*, *walking skeleton* — is defined once in the shared,
harness-agnostic [`GLOSSARY.md`](./GLOSSARY.md). Definitions live there so this
specification and any binding cite the same source.

---

*This is the canonical, harness-agnostic specification of the workflow.
Concrete bindings — a specific command set, named agents, file layouts — derive
*from* this document, not the other way around; it deliberately omits all
tool-specific detail. Map the roles and stages above onto whatever harness you
use.*
