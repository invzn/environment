# A Complexity-First LLM SDLC

A high-level workflow for building software with LLM agents, organized around a
single idea from John Ousterhout's *A Philosophy of Software Design*:

> **The greatest limit on software development is complexity, and good design is
> the continuous fight to minimize it.**

This is agent-agnostic — it describes *what* happens and *why*, not which
harness, command set, or tools you bind it to. It answers one question: *"how do
I keep the LLM from burying me in complexity?"* Everything below derives from
that.

---

## The core premise: the LLM is a tactical-programming engine

Ousterhout draws the central distinction between
[**tactical** and **strategic** programming](./GLOSSARY.md#tactical-vs-strategic-programming).
Tactical = get it working; complexity accretes one expedient choice at a time.
Strategic = working code isn't the goal — a *great design* is — bought with a
continuous ~10–20% investment.

An LLM is the most efficient tactical-programming engine ever built. It will
produce working-but-shallow code with near-zero friction, forever, and it will
do so *persuasively* — fluent, plausible, and confident even when the underlying
abstraction is wrong. Left alone it drives
[complexity toward its three symptoms](./GLOSSARY.md#complexity)
unchecked:

- **Change amplification** — it duplicates instead of factoring, so one change
  later needs many edits.
- **Cognitive load** — it exposes configuration and edge cases through the
  interface rather than absorbing them.
- **Unknown unknowns** — the worst — it produces code that *looks* obvious but
  hides decisions the next reader (human or agent) can't see.

So the workflow's job is not to slow the LLM down. It is to **insert strategic
checkpoints at exactly the points where the LLM's fluency would otherwise let
complexity accumulate silently.** Every stage below exists because there is a
specific, predictable way the model adds complexity there.

---

## Roles

Four logical roles (one person or agent may play several):

- **The human** — sets the complexity budget and is the final arbiter of whether
  a design is *deep enough*. Strategy is imposed by this role; the model will not
  volunteer it.
- **The lead agent** — drives the stages, runs design-it-twice, writes the
  interface contracts, and holds the line against tactical shortcuts.
- **An implementing agent** — writes the code behind a settled interface.
- **A reviewing agent** — runs the red-flag audit adversarially against the
  implementation.

---

## Non-negotiables

Two rules drive everything below.

1. **Complexity is the acceptance criterion, not correctness.** "It works" and
   "the tests pass" are necessary, never sufficient. Every change is judged on
   whether it reduces or adds complexity — measured by the three symptoms above,
   recognized through the [design red flags](./GLOSSARY.md#design-red-flags).
   A passing diff that adds a shallow module is a *failure*.

2. **Strategy must be actively imposed; the default is tactical.** Because the
   LLM always offers the working-but-shallow path, every strategic step here —
   design-it-twice, interface-comment-first, the red-flag audit — is a
   **deliberate act the human or lead must force**, never something assumed to
   have happened. An un-refuted red flag blocks the merge.

The first rule defines *what good means*; the second admits *who has to want it*.
Neither is free, and skipping either collapses the workflow back into "ask the
model, ship what it returns."

---

## Why it is shaped this way

The spine is Ousterhout's, applied to an agent that is fluent, fast, and
tactical by nature. Three of his practices *generate* the shape:

- [**Design it twice.**](./GLOSSARY.md#design-it-twice) Even experts produce better designs when forced to
  consider radically different alternatives before choosing. This is the one
  practice the LLM makes *cheaper*, not harder — generating a second and third
  divergent design costs almost nothing — so it moves from "nice to have" to a
  load-bearing stage.
- **Write the interface comment first.** The interface contract is a design tool,
  not documentation. Writing it before the implementation exposes a shallow or
  fuzzy abstraction *before* code is committed to it — and it is the cheapest
  defense against the model rationalizing a muddy interface after the fact.
- **Pull complexity downward / define errors out of existence.** The module
  developer should suffer complexity so the many callers don't. The LLM's default
  is the opposite — expose knobs, raise exceptions — so this is stated as an
  explicit implementation instruction, not left implicit.

Two more practices *protect* the shape rather than generate it:

- **Red-flag recognition.** Ousterhout teaches warning signs, not rules. The
  model produces a *characteristic* subset of them (see stage 5), so a dedicated
  adversarial audit keyed to that subset is the highest-yield review in the
  cycle.
- **Continual redesign.** Fix design problems as you meet them; resist "the
  smallest possible change." The model's instinct is always the smallest local
  patch, so keeping the surrounding design clean is an explicit integration step.

> Note on TDD: Ousterhout is skeptical of test-driven development precisely
> because it can *encourage tactical work* — making the next test pass rather
> than designing. This workflow keeps tests, but **subordinate to design**: design
> is settled in stages 1–3; tests *lock* behavior in stage 4, they do not *drive*
> it.

---

## The stages

Each stage is a discrete step with a natural human gate and easy re-entry. The
order is a **default, not a one-way gate**: any stage may send you back to revise
an earlier decision, after which you re-run forward.
The recurring question at every stage is the same — *did the model just hand me
the tactical answer?*

### 1. Frame the strategic intent

- **In:** a problem or goal.
- **Do:** decide what **knowledge** this change owns and what is **likely to
  change** behind it — the two things that determine where the deep module's
  boundary should fall. Set an explicit
  [**complexity budget**](./GLOSSARY.md#complexity-budget): what is
  allowed to get harder, and what must stay simple. Do *not* prompt for code.
- **Out:** the owned knowledge, the expected axis of change, the budget.
- **Gate: hard.** This is the cheapest point to correct a misframing — before any
  design or code is committed to it.
- **The LLM failure this guards:** asked to "make it work," the model frames the
  problem tactically around the immediate symptom and never identifies the
  knowledge worth hiding.

### 2. Design it twice

- **In:** the strategic intent.
- **Do:** have the lead agent generate **two or more radically different**
  designs — not variations, genuinely different abstractions. Judge them on
  **depth** (powerful behavior behind a simple interface) and **information
  hiding** (which decisions stay encapsulated), not on which is easiest to build.
- **Out:** the chosen abstraction and *why it is deeper* than the runners-up.
- **Gate: hard.** This is the design commitment.
- **The LLM failure this guards:** the model's first design is its most
  conventional one. Without a forced second attempt, you ship the obvious shallow
  decomposition.

### 3. Specify the interface (comment-first)

- **In:** the chosen abstraction.
- **Do:** write the **interface contract before any implementation** — the
  interface comment as design instrument. If the contract is long, vague, full of
  special cases, or *hard to name*, the abstraction is wrong: **backtrack to
  stage 2**, don't write the code anyway.
- **Out:** a narrow interface with a contract short enough to describe cleanly.
- **Gate: critique.** Run an analytical pass — *is this a deep module, or did we
  just name a shallow one?* Screen specifically for the interface-altitude
  [red flags](./GLOSSARY.md#design-red-flags): shallow module,
  information leakage, overexposure, special-general mixture, pass-through method.
- **The LLM failure this guards:** the model writes a plausible interface and an
  implementation that fits it, retroactively making a bad abstraction look
  intentional. Writing the contract first denies it that move.

### 4. Implement, pulling complexity downward

- **In:** the settled interface.
- **Do:** let the implementing agent write the body — under two standing
  instructions that counter the model's defaults:
  - [**Pull complexity downward**](./GLOSSARY.md#pull-complexity-downward)
    — absorb configuration, defaults, and edge cases *inside* the module rather
    than exposing them through the interface.
  - [**Define errors out of existence**](./GLOSSARY.md#define-errors-out-of-existence)
    — design the semantics so error cases
    can't arise (clamping, sensible defaults, idempotent operations) instead of
    proliferating exceptions the callers must handle.
  Tests are written here to **lock** the contract's behavior — not to drive the
  design, which is already settled.
- **Out:** an implementation behind the unchanged interface, with behavior pinned
  by tests.
- **The LLM failure this guards:** the model exposes knobs and raises exceptions
  by default, pushing complexity *up* to every caller.

### 5. Red-flag audit

- **In:** the implementation.
- **Do:** a **reviewing agent runs an adversarial complexity audit** against the
  full [red-flag list](./GLOSSARY.md#design-red-flags), prompted to
  *find* flaws, not to bless the code. Weight the audit toward the flags LLMs
  produce characteristically:
  - [**Classitis**](./GLOSSARY.md#classitis) — over-decomposition
    into many tiny shallow classes/functions, mistaking small for simple.
  - **Pass-through methods** — layers that only forward calls, adding interface
    without functionality.
  - **Repetition** — re-deriving logic instead of reusing an existing
    abstraction (the model often can't see what already exists).
  - **Comment repeats code** — narration of *what* the line does instead of the
    non-obvious *why*.
  Each finding is either repaired (pull complexity down, deepen the interface,
  factor the repetition) or explicitly refuted with reasoning.
- **Out:** an implementation with every flag repaired or refuted.
- **Gate: the key LLM-specific gate.** Per non-negotiable 2, an un-refuted flag
  blocks the merge. This is where most model-generated complexity is caught.

### 6. Integrate by continual redesign

- **In:** the audited change.
- **Do:** fold it into the system **without patching**. Where it doesn't fit
  cleanly, refactor the surrounding design to keep the whole clean — explicitly
  **reject the "smallest possible change"** the model will propose. Then the human
  reviews: the final judgment is whether the *system's* total complexity went down
  or at least held flat.
- **Out:** a merged change that left the codebase no more complex than it found
  it — ideally less.
- **Gate: human.** The final arbiter of "deep enough."
- **The LLM failure this guards:** the model bolts the change on at the seam,
  optimizing for a minimal diff and leaving the surrounding design to rot.

---

## At a glance

```
problem
  │
  ▼
[1] Frame strategic intent   (owned knowledge, axis of change, budget)   ── hard gate
[2] Design it twice          (≥2 divergent designs; pick the deepest)     ── hard gate
[3] Specify interface        (contract first; hard-to-describe → back to 2) ── critique gate
[4] Implement                (pull complexity down; errors out of existence; tests lock)
[5] Red-flag audit           (adversarial; classitis / pass-through / repetition / …) ── block on un-refuted flag
[6] Integrate                (continual redesign, never the smallest patch) ── human gate
  ▲
  └── any stage may backtrack and re-run forward
```

The throughline, restated: **complexity is the enemy; deep modules + information
hiding are the weapons; and stages 2, 3, and 5 are strategic checkpoints placed
exactly where an unsupervised LLM accumulates complexity fastest.**

---

## Glossary

All terminology this specification uses — *complexity*, *deep* / *shallow
module*, *interface*, *design red flags*, *tactical vs. strategic programming*,
and the rest — is defined in the self-contained
[`GLOSSARY.md`](./GLOSSARY.md) beside this document, so the workflow stands on its
own. The conceptual summary of *A Philosophy of Software Design* this workflow is
built on lives in
[`PHILOSOPHY_OF_SOFTWARE_DESIGN.md`](../PHILOSOPHY_OF_SOFTWARE_DESIGN.md).

---

*This is the canonical, harness-agnostic specification of the complexity-first
SDLC. Concrete bindings — a command set, named agents, file layouts — derive from
this document, not the other way around.*
