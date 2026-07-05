# An Agent-Agnostic LLM Development Workflow

> **Status: retired.** Superseded by the complexity-first SDLC in
> [`../philosophy_sdlc/PHILOSOPHY_SDLC.md`](../philosophy_sdlc/PHILOSOPHY_SDLC.md);
> its `/wf-*` command binding has been removed and this spec is no longer
> deployed to `~/.claude/references/`. Kept for the machinery the successor
> deliberately omits — depth routing, Lite/Full tiers, the tracer-bullet
> skeleton / interface lock, and MR sizing/batching — which may be folded into
> the successor if usage demands it.

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

These two rules drive almost every other decision below. The binding resource
is the **sole human's comprehension of agent output** — not their time or
review effort, but their ability to *fully understand* what the agents
produced, at their own pace. "Reviewable in one sitting" is a proxy for
**comprehensible as one unit**. So the unit of delivery is sized to what a
person can absorb at once, and "split the module," "batch the reviews," and
"comprehension-not-line-count" below are all corollaries of this single
constraint, not independent rules.

Comprehension is purchased by **structure**, not prose: deep modules, narrow
interfaces, and small sibling merge requests are what let the human understand
the output. The design doc (below) is the implementing agent's spec; the human
may consult it as reference, but it is not what makes the output comprehensible
— the decomposition is.

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
> transfer cleanly here — there is no team. The binding resource is the sole
> human's comprehension of agent output (see Non-negotiables), which is why
> increments are sized "reviewable in one sitting."

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
skeleton-first / interface-lock machinery exists to prevent **interface drift
between independently-built modules** — to stop a shared interface from being
committed by several modules *before* it has been validated. It is about
interface-drift *correctness*, not throughput; parallelism is a permitted
side-effect, not the goal. The trigger is therefore not raw module count but
**whether multiple modules will commit to shared interfaces before those
interfaces are validated**. In a strictly sequential build, a wrong interface
is corrected for free by backtracking — nothing else is in flight — so the
skeleton earns its keep only when interfaces are committed as a set ahead of
validation, which parallel construction does by definition.

| Tier | When | What runs |
|---|---|---|
| **Fast path** | No deep module | A lightweight implement cycle: TDD → agent review → merge request → human review. No up-front design pipeline. |
| **Lite** | No shared interfaces are committed before validation — a single deep module, or several built strictly one-at-a-time | The full design pipeline (stages 1–4) + Implement. **Skip the skeleton / interface-lock** — a wrong interface is corrected for free by backtracking, since nothing else is in flight. |
| **Full** | Multiple deep modules will commit to shared interfaces before those interfaces are validated (the usual case when they are built concurrently) | All six stages. The skeleton increment locks interfaces before the modules are deepened against them. |

- **Two routing clocks.** The route is not one three-way decision made up
  front; it is two decisions made at two different times, because they key on
  things knowable at two different times.
  - **Up front (cheap smell): Fast vs. heavy.** "Does this introduce *any* deep
    module?" This is a genuine back-of-envelope call — you can usually smell
    that something hides real complexity behind a narrow interface before
    designing it. It runs on a *cheap depth smell*, **not** the committed
    stage-2 abstract solution (which only the heavy track produces, so keying on
    it would be circular).
  - **At the exit of the Module stage (informed, near-free): Lite vs. Full.**
    Whether multiple modules will commit to shared interfaces before validation
    is only visible *after* decomposition. By stage 4 you are looking right at
    the interface list, so the call is nearly free. Stages 1–4 are identical for
    Lite and Full; the tier is just a flag set at stage 4's exit (skeleton or
    not). The lead agent recommends; the human confirms or overrides.
  - Because Lite-vs-Full is *deferred* rather than guessed, escalation is no
    longer needed to absorb a wrong tier guess. **Escalation now covers only the
    genuine surprise:** fast-path work that turns out to hide a deep module,
    which stops and re-enters the heavy track at Design/Module.
- **Escalation is allowed mid-flight.** Beyond the up-front fast→heavy case
  above, a Lite task already in Implement may surface a second deep module that
  shares interfaces with the first; when it does, stop and escalate to Full,
  adding the skeleton increment before the shared interfaces are committed by
  both.
- **Reviewability on the fast path.** The fast path has no Module stage, so it
  cannot use module-splitting to stay reviewable. Two cases:
  - *Mechanical* work (renames, reformats, dependency bumps, large mechanical
    rewrites) stays reviewable in one sitting by the
    **comprehension-not-line-count** rule — but the exemption is conditional:
    **mechanical work counts as one unit of comprehension only when a machine,
    not the human, guarantees it changed only what it should** (a type checker,
    a green test suite, a deterministic AST refactor — not an agent free-handing
    edits across 200 files). The human comprehends the intent and audits the
    guarantee. With no such guarantee the human is back on the hook for every
    site, the exemption is void, and the work must be split or independently
    verified.
  - *Heavy-but-shallow behavioral* work (substantial new logic behind a stable
    interface) gets no such exemption and is kept reviewable by **splitting it
    into multiple sequential merge requests**. The seam, mirroring the
    heavy-track module rule: **split by behavior-cluster in dependency order** —
    each MR is one comprehensible cluster of related behavior that depends only
    on behaviors already merged (the same "one behavior at a time" unit the TDD
    loop already privileges). And the same escape hatch as the module rule: if
    the behavior won't cut cleanly — a behavior in MR-2 would depend on an
    unmerged half of MR-1 — **don't fabricate a cut; take the larger MR and flag
    it.** "Split the module, never the MR" is a heavy-track rule; the fast path
    splits the MR because it has no module to split.
- **Status: provisional.** This routing rule has zero real runs behind it.
  Revisit after ~10 uses.

---

## The accreting document

A single design doc is the **single source of truth**. It grows **one section
per stage** and lives **in the target repository, on the feature branch**,
committed — so it is versioned, travels with the code, is itself reviewable,
and survives across sessions. Its **primary audience is the implementing agent**
— it is a spec. The human may consult it as reference, but the human's
comprehension is carried by the decomposition, not by this document.

Backtracking happens here: any stage may revise an earlier section in place,
after which you re-run forward from that point.

**Under Full-tier parallel construction the doc is frozen and funneled.** Once
the skeleton merges, the design doc is locked exactly like the interfaces it
records: it is read-only on module branches, and every canonical edit goes
through the **base/skeleton branch** — the same discipline, and the same
"expensive exception" recovery, as an interface change. This keeps "single
source of truth" literally true: there is exactly one writable copy at any time.
A module that discovers a legitimate refinement records it cheaply as a
**proposed doc delta** in its merge request (one sentence in the description);
the lead agent folds accepted deltas into the base doc at merge time. The
canonical doc only ever mutates via the base branch.

---

## The three altitudes

The middle stages (Design, Module, Implement) are genuinely distinct
*altitudes* of the same problem. One rule keeps them from collapsing into each
other — but it is a **default-placement heuristic, not a strict partition**:

> **Decide each thing at the highest altitude where you have enough information
> to decide it, and no higher.** Behavioral decisions tend to land in Design,
> interfaces in Module, and concrete technology in Implement — because that is
> the first altitude at which each can be responsibly committed.

The altitudes are a spectrum, not three sealed rooms: an interface signature
inevitably re-encodes — and sometimes sharpens — the behavioral choices made in
Design (the choice of `Take(n) → remaining` vs. `Check → allowed` vs.
`Reserve/Commit` is itself a behavioral commitment). Don't litigate which room a
decision "belongs" to. When a Module-stage signature reveals that a Design-level
behavioral statement was underspecified, that is simply a **backtrack to
Design** — re-run forward. No new mechanism; it is the backtracking the workflow
already allows.

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
- **Gate: optional, and agent-initiated.** The Design stage consumes stages
  1–3 as a single artifact, so pausing here serves only the human. But the human
  has not seen this choice yet, so they cannot be the one to "contest" it — the
  **lead agent decides whether to surface the pause.** Default is to fold the
  conversation into Design; the lead agent raises the gate only when it judges
  the mechanism-family choice to be a genuine live fork — more than one credible
  family with materially different consequences, or a choice expensive to reverse
  once Design builds on it. When the choice is obvious or forced, no pause. The
  test is the lead agent's, made on the human's behalf: *would the human want to
  weigh this fork before I commit Design to one arm of it?*

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
- **Gate: critique.** This is the first of **three layered interface checks**,
  each catching a failure class the others structurally cannot (see Planning and
  Gates & feedback for the other two). The critique gate is the **analytical**
  one: before any code, run a critique pass on the design and interfaces (an
  architecture/design review, or an adversarial grilling) asking *are these the
  right interfaces — deep, well-factored, hiding the right complexity?* It cannot
  catch "they don't actually compose," because nothing is wired yet — that is
  the skeleton's job. Interface mistakes are the costliest to undo, which is why
  three checks guard them and none of the three is redundant.

### 5. Planning

- **In:** doc through module specs.
- **Do:** create the list of implementation tasks. **One deep module = one
  task = one merge request.**
- **Sequencing (Full tier only):**
  - The first increment is the **skeleton**: all interfaces + stub
    implementations + one passing end-to-end test proving the contracts
    compose. The design doc and agreed interfaces land in this base branch;
    every subsequent module branches from it. Stubbing every interface at once
    may look like the horizontal "all-interfaces-then-all-code" split that
    stage 6 warns against — it is the opposite. The skeleton is a **vertical**
    tracer: one thin path through *all* the stubs, not one *layer* built out
    across all features. No module is implemented; the stubs exist only to prove
    the path composes. The skeleton carries the **second and third interface
    checks**. Its passing end-to-end test is the
    **automated/empirical** check — it proves the contracts *mechanically*
    compose (types line up, the path runs), which the analytical critique gate
    cannot, but it says nothing about whether the decomposition is *right* (a bad
    design composes fine). Its human review is the **interface-lock gate** — the
    highest-leverage human review in the whole Full tier, because this MR *is*
    the lock: every parallel module branches from it, and per the Non-negotiables
    these locked interfaces are what make the eventual output comprehensible to
    the human. **Do not rubber-stamp it.** It looks like trivial scaffolding
    ("just stubs and one test"), but the review question is *"are these the right
    interfaces to lock?"* — not *"does this scaffolding look fine?"* This is the
    one review that deserves *more* human scrutiny, not less. Stubbing every
    interface, wiring them, and writing an end-to-end test is real work; none of
    the three checks is "cheap," and pretending otherwise is how the lock gets
    rubber-stamped.
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
- **Lite tier:** skip the skeleton — no shared interface is committed before
  validation, so there is nothing for the skeleton to lock. The plan is the
  module(s) in sequence; a wrong interface is corrected for free by backtracking
  because nothing else is in flight.
- **Out:** + **list of tasks**.

### 6. Implement

- **In:** one task.
- **Do:** the per-task cycle:
  1. **TDD loop** — red → green → refactor, **one behavior at a time.** (Not
     all-tests-then-all-code; that horizontal split is an anti-pattern.)
  2. **Agent review + fix** — a code-review agent and a standards-review agent
     (plus optional specialists); findings applied. The standards review
     explicitly screens for the
     [**design red flags**](./GLOSSARY.md#design-red-flags) from *A Philosophy of
     Software Design*, since the implementation is where module- and code-level
     complexity surfaces. The interface-altitude flags (shallow module,
     information leakage, special-general mixture, overexposure) are also caught
     at the stage-4 **critique gate** before any code exists; here the full set
     is checked a second time against the concrete implementation. Beyond
     flagging, findings drive the repairs the workflow otherwise leaves implicit:
     **pull complexity downward**, **define errors out of existence**, and
     **prefer deeper, more general-purpose interfaces.**
  3. **Clean merge request** opened.
  4. **Human review** — the final gate.
- **Out:** a merge request.
- Reviews of parallel module merge requests are **batched** — collected and
  presented to the human together. The point is **not** to reduce agent
  round-trip latency (the agents are not the bottleneck); it is to **package
  agent output into the shape a single human can fully absorb.** Full-tier
  modules are interface-isolated siblings off one skeleton, so reviewing them as
  a batch lets the human page the shared interfaces and design into working
  memory *once* and amortize that context across the whole batch — cheaper *per
  module* than reviewing them scattered across days. Batching does **not** merge
  them into one oversized review: each merge request remains its own one-sitting
  unit (interface-isolation is what makes this legitimate), and a batch has an
  **optimal size** — past the human's session capacity, comprehension degrades
  and the batch should be split. More is not better.

---

## Gates & feedback

- **Human gates exist for the human, not the agent.** The Design stage consumes
  the doc *through stage 3* as one artifact, so the pause boundaries within
  stages 1–3 serve only the human's ability to catch a mistake early.
  **Requirements (1) and Design (3) are hard gates; the Abstract-Solution (2)
  gate is optional and agent-initiated** — the lead agent surfaces it on the
  human's behalf only when the mechanism-family choice is a genuine live fork
  (see stage 2), since the human has not yet seen the choice to contest it.
- **Three layered interface checks** guard the interfaces before deep
  investment, each catching what the others structurally cannot: the **critique
  gate** (between Module and Planning) is *analytical* — is this the right
  design?; the **skeleton's end-to-end test** is *automated* — do the contracts
  mechanically compose?; the **skeleton MR's human review** is the
  *interface-lock gate* — the deepest-scrutiny human review in Full tier, where
  the interfaces are locked and the human's own comprehension scaffold is set.
  None is redundant and none is "cheap."
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
