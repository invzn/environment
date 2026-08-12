# Design Patterns — a complexity-first catalog

A reference catalog of software design patterns for the
[complexity-first SDLC](./PHILOSOPHY_SDLC.md), written to be read by design and
audit agents at runtime.

**A pattern is a pre-packaged abstraction, not a goal.** Ousterhout's warning
governs this whole file: *the greatest risk with design patterns is
over-application* — using one where a simpler bespoke design would do adds
interface without adding functionality, which is the definition of a
[shallow module](./GLOSSARY.md#shallow-module). So every entry here is judged by
the same two criteria as any other design — **depth** (functionality hidden per
signature exposed) and **information hiding** (which decisions stay
encapsulated) — and every entry names its own misapplication.

## How the SDLC uses this catalog

- **Stage 2 (design it twice):** pattern *families* are vantage seeds for the
  independent design agents — one agent may design from the pipeline vantage,
  another from the event vantage. **A pattern is a vantage, never a verdict**:
  the design is still judged on depth, and two designs that are both "Strategy
  with different names" fail the radical-difference test.
- **Stage 3 (interface):** if the contract fits a named pattern, the name is
  free documentation — say so in the interface comment. If the design fits *no*
  name here and won't take a crisp name of its own, that is the
  *hard-to-pick-name* red flag.
- **Stage 5 (red-flag audit):** each entry's **Red flag when** line is the
  pattern's characteristic shallow form. Code shaped like one is a finding
  under the matching [design red flag](./GLOSSARY.md#design-red-flags) — LLMs
  reach for patterns fluently and over-apply them characteristically (a
  Strategy with one strategy, a Factory over one type, a pass-through Facade).

Entry format — four lines, always the same four:
intent; **Hides** (the information-hiding claim); **Deep when** (the axis of
change it genuinely absorbs); **Red flag when** (the shallow form an auditor
should hunt).

---

## Creational

### Factory Method
Defer which concrete type gets instantiated to one overridable creation point.
- **Hides:** the concrete class chosen and its construction details.
- **Deep when:** creation genuinely varies by configuration or subtype, and callers must stay ignorant of the variants.
- **Red flag when:** it only ever constructs one type — a pass-through over `new`.

### Abstract Factory
One interface that creates a *family* of related objects that must vary together.
- **Hides:** which variants belong together — the consistency rule of the family.
- **Deep when:** whole families swap as a unit (render backends, storage engines, test doubles for a subsystem).
- **Red flag when:** the family has one member, or only one family exists — double indirection with nothing to keep consistent.

### Builder
Assemble a complex object stepwise; validate invariants once, at completion.
- **Hides:** construction order, intermediate state, and defaults.
- **Deep when:** many optional parts with cross-field invariants that must hold before the object exists.
- **Red flag when:** its setters mirror constructor arguments one-for-one — overexposure with extra steps; named/default arguments or a config struct is deeper.

### Prototype
Create new instances by cloning a configured exemplar.
- **Hides:** the cost and detail of building from scratch.
- **Deep when:** instances are expensive to configure and mostly alike.
- **Red flag when:** the language already gives cheap literals or copy semantics — the pattern re-derives what exists ([repetition](./GLOSSARY.md#design-red-flags)).

### Singleton
Exactly one instance, globally reachable.
- **Hides:** the instance count — and almost nothing else; it *exposes* global mutable state to every corner of the program.
- **Deep when:** nearly never. A dependency constructed once and passed explicitly hides more and couples less.
- **Red flag when:** used to dodge deciding ownership — hidden coupling, untestable seams, the unknown-unknowns symptom in miniature.

### Object Pool
Reuse expensive-to-create instances instead of reallocating.
- **Hides:** lifecycle, reuse, and invalidation policy.
- **Deep when:** allocation cost is *measured* (connections, threads, large buffers).
- **Red flag when:** pooling cheap objects — complexity spent with no measured payoff, plus stale-state bugs bought for free.

---

## Structural

### Adapter
Convert an interface you have into the one your callers need.
- **Hides:** the foreign interface's shape and quirks; keeps its vocabulary from leaking into yours (anticorruption layer at system scale).
- **Deep when:** isolating a third-party or legacy API so the axis of change (vendor, version) stays behind one wall.
- **Red flag when:** adapting between two interfaces you both own — redesign one instead of taxing every call with a translation layer.

### Facade
One simple interface over a messy or many-part subsystem.
- **Hides:** subsystem topology, call ordering, and wiring — the canonical [deep module](./GLOSSARY.md#deep-module) move.
- **Deep when:** the common case collapses to a few calls while the subsystem stays independently evolvable behind it.
- **Red flag when:** its signatures re-export the subsystem's types (information leakage) or its methods forward 1:1 (pass-through method).

### Bridge
Split an abstraction hierarchy from its implementation hierarchy so both vary independently.
- **Hides:** which implementation backs which abstraction.
- **Deep when:** two axes of change genuinely vary independently, today — shapes × renderers, protocols × transports.
- **Red flag when:** one axis has a single member — you paid for two hierarchies and got one.

### Composite
One uniform interface over both leaves and containers in a part–whole tree.
- **Hides:** whether the caller holds one element or a subtree — it [defines the one-vs-many distinction out of existence](./GLOSSARY.md#define-errors-out-of-existence).
- **Deep when:** callers genuinely operate on parts and wholes with the same verbs.
- **Red flag when:** leaves and containers don't share real operations — forced uniformity that breeds "unsupported operation" errors (special-general mixture).

### Decorator
Layer optional behavior by wrapping the same interface.
- **Hides:** which augmentations are active behind the base interface.
- **Deep when:** independent add-ons genuinely compose — buffering over encryption over a byte stream.
- **Red flag when:** wrappers proliferate as shallow single-method layers. Ousterhout's own caution: consider putting the behavior in the underlying class before reaching for a wrapper.

### Proxy
A stand-in that controls access to the real object — lazy, remote, cached, guarded.
- **Hides:** the real object's locality, cost, or access policy.
- **Deep when:** the policy is substantial — caching with invalidation, auth checks, lazy faulting.
- **Red flag when:** it forwards transparently with no policy — a pass-through layer wearing a pattern name.

### Flyweight
Share immutable intrinsic state among many logical objects.
- **Hides:** the sharing; callers see plain objects.
- **Deep when:** memory pressure is *measured* and intrinsic/extrinsic state split cleanly.
- **Red flag when:** applied speculatively — the split contaminates every interface that must now carry extrinsic state.

---

## Behavioral

### Strategy
Encapsulate interchangeable algorithms behind one interface, selected at runtime.
- **Hides:** which algorithm runs and its tuning.
- **Deep when:** the algorithm itself is the axis of change and ≥2 real variants exist *today*.
- **Red flag when:** one concrete strategy exists and the second is hypothetical — speculative generality; a plain function (or function argument) is deeper.

### Template Method
Fix an algorithm's skeleton in a base class; let subclasses fill designated steps.
- **Hides:** the ordering and orchestration of the steps.
- **Deep when:** the skeleton is truly invariant and the steps vary independently.
- **Red flag when:** a step can't be understood without reading the skeleton and vice versa — conjoined methods split across an inheritance boundary; prefer composition (Strategy) or one honest method.

### Observer / Publish–Subscribe
Producers emit events; consumers subscribe — neither knows the other.
- **Hides:** who reacts to a change.
- **Deep when:** fan-out is real, reactions are independent, and adding a subscriber must not touch the producer.
- **Red flag when:** there is one known subscriber — a direct call is more obvious. Note the price even when justified: control flow becomes invisible, spending the *unknown unknowns* budget; account for it in §1.

### Command
Reify an operation as an object so it can be queued, undone, logged, retried.
- **Hides:** *when* and *where* an operation runs from *what* it does.
- **Deep when:** something real uses the reification — scheduling, undo stacks, persistence, retries.
- **Red flag when:** commands wrap a single method call and nothing queues, undoes, or logs them — classitis with ceremony.

### State
Move state-specific behavior into state objects; transitions swap the object.
- **Hides:** the transition table and per-state branching.
- **Deep when:** many states each carry real behavior, and invalid transitions can be made unrepresentable ([errors out of existence](./GLOSSARY.md#define-errors-out-of-existence)).
- **Red flag when:** two or three states with a line of behavior each — an enum and a `switch` is more obvious and more honest.

### Chain of Responsibility
Pass a request along handlers until one accepts it.
- **Hides:** which handler will decide.
- **Deep when:** handlers are genuinely independent and their set changes (middleware with real per-layer behavior).
- **Red flag when:** the chain's *order* is load-bearing but invisible at any call site — nonobvious code; a dispatch table names the routing rule outright.

### Iterator
Sequential access to a collection without exposing its representation.
- **Hides:** the traversal machinery and the underlying structure.
- **Deep when:** built into the language — use that. Implement your own only for a custom traversal order worth hiding.
- **Red flag when:** a hand-rolled iterator re-derives what the standard library provides (repetition).

### Mediator
Centralize many-to-many peer interactions into one coordinator.
- **Hides:** the peer-to-peer wiring; peers know only the mediator.
- **Deep when:** N×N coupling between peers is real and the interaction rules form a coherent policy worth naming.
- **Red flag when:** the mediator grows into a god object — the coupling wasn't reduced, just relocated and renamed.

### Memento
Externalize a snapshot of an object's state without exposing its internals.
- **Hides:** the representation of the saved state.
- **Deep when:** undo, rollback, or crash recovery is a stated requirement.
- **Red flag when:** snapshots are taken "in case" — state to maintain with no consumer.

### Visitor
Add operations across a stable type hierarchy without modifying it.
- **Hides:** operation dispatch over the hierarchy.
- **Deep when:** *operations* are the axis of change and the *hierarchy* is genuinely frozen.
- **Red flag when:** the hierarchy still changes — every new type amplifies through every visitor. This pattern is a bet on which axis moves; audit the bet, not the code.

### Null Object
A do-nothing implementation stands in for "absent," eliminating null checks.
- **Hides:** the present/absent distinction — [defining the null-check error out of existence](./GLOSSARY.md#define-errors-out-of-existence) at every call site.
- **Deep when:** "do nothing" is a *correct* behavior for absence, not a silent one.
- **Red flag when:** it swallows behavior callers needed to observe — an error defined out of existence is only a win if nobody needed the signal.

---

## Architectural

### Layered Architecture
Strict one-direction dependencies; each layer speaks a distinct vocabulary.
- **Hides:** everything below the layer a caller touches.
- **Deep when:** each layer *changes the abstraction* — different layer, different vocabulary.
- **Red flag when:** adjacent layers expose near-identical interfaces — the pass-through method at architecture scale, and the single most common layering failure.

### Ports & Adapters (Hexagonal)
The domain core defines the interfaces (ports); infrastructure implements them at the edges (adapters).
- **Hides:** I/O technology — database, queue, HTTP — from domain logic.
- **Deep when:** the technology is the axis of change, or the core must be testable without infrastructure.
- **Red flag when:** a port mirrors one vendor's API one-for-one — the "abstraction" is the vendor's interface with your name on it (information leakage).

### Pipes & Filters (Pipeline)
Independent stages transform data flowing through a uniform medium.
- **Hides:** each stage's internals; composition *is* the interface.
- **Deep when:** stages are independently testable, reorderable, and share nothing but the medium.
- **Red flag when:** stages coordinate through hidden shared state, or the "uniform" medium accretes per-stage flags — a special-general mixture flowing through every stage.

### Event-Driven Architecture
Components communicate by emitting and consuming events, at system scale.
- **Hides:** who consumes an event and when.
- **Deep when:** producers and consumers must evolve and deploy independently, and eventual consistency is acceptable *and stated*.
- **Red flag when:** a synchronous workflow is dressed up as events — you pay the obviousness tax (invisible control flow, delivery semantics, idempotency) and get no decoupling back.

### Plugin (Microkernel)
A stable core plus a contract that extensions implement.
- **Hides:** each extension's internals from the core, and the core's internals from extensions.
- **Deep when:** extensions are the product's axis of change and the contract stays put while they churn.
- **Red flag when:** the "stable" contract changes with every new plugin — the boundary is drawn in the wrong place; redesign it before admitting more plugins.

### Repository
A collection-like interface over persistence: add, remove, find.
- **Hides:** storage technology and query construction.
- **Deep when:** domain code can treat persistent objects as an in-memory collection and the storage tech can change behind it.
- **Red flag when:** it leaks ORM/driver types through its signatures, or grows a bespoke method per caller query — an interface that scales with its callers is shallow by definition.

### Unit of Work
Track changes across a business operation; commit them atomically.
- **Hides:** transaction boundaries, write ordering, and dirty-tracking.
- **Deep when:** one business action spans several mutations that must land together.
- **Red flag when:** your ORM already provides it and you build another on top — repetition, at a layer where the bugs are expensive.

### MVC / MVP / MVVM
Separate presentation from domain state, with a mediating controller/presenter/view-model.
- **Hides:** rendering and input concerns from domain logic (and vice versa).
- **Deep when:** the same domain state serves multiple views, or view tech is the axis of change.
- **Red flag when:** logic pools in the mediating layer while the "model" is anemic data — the separation is nominal and every change lands in the god-controller.

### CQRS
Separate the write model (invariants) from the read model (query shapes).
- **Hides:** read-side optimization from write-side correctness.
- **Deep when:** read and write needs have *measurably* diverged — different shapes, different scale, different consistency.
- **Red flag when:** adopted on principle: two models plus synchronization is a large complexity-budget line item, and the default answer is one model.

### Event Sourcing
Current state is a fold over an immutable event log.
- **Hides:** how present state is derived; buys audit, replay, and temporal queries.
- **Deep when:** the event history *is* domain knowledge — audit and replay are requirements, not aspirations.
- **Red flag when:** chosen for "auditability" a history table would cover — schema evolution, projections, and rebuilds are a permanent tax on every future change.

---

## Concurrency & resilience

### Producer–Consumer
Decouple producers from consumers through a queue.
- **Hides:** rate mismatch and burstiness between the two sides.
- **Deep when:** rates genuinely differ and the queue's bound/backpressure policy is explicit in the contract.
- **Red flag when:** the queue is unbounded and backpressure unstated — the failure mode was hidden, not handled.

### Worker Pool
A bounded set of workers draining a shared queue.
- **Hides:** scheduling, parallelism limits, and worker lifecycle.
- **Deep when:** concurrency must be bounded and work items are independent.
- **Red flag when:** pool size and rejection policy leak to every caller — the knobs were pushed up instead of [down](./GLOSSARY.md#pull-complexity-downward).

### Actor
State owned by exactly one sequential actor; all interaction via messages.
- **Hides:** locking entirely — it defines data races out of existence for the state it owns.
- **Deep when:** state partitions cleanly by owner and interactions are genuinely asynchronous.
- **Red flag when:** actors call each other request-reply in chains — synchronous coupling rebuilt with worse debuggability and mailbox deadlocks.

### Circuit Breaker
Stop calling a failing dependency; fail fast, probe for recovery.
- **Hides:** dependency-health policy from every call site.
- **Deep when:** the dependency does fail, and cascading retries would amplify the outage.
- **Red flag when:** thresholds and half-open probing leak into caller code — the policy belongs inside the breaker, exposed as one call.

### Retry with Backoff
Absorb transient failure by retrying with increasing delay.
- **Hides:** the transience of the failure from the caller.
- **Deep when:** the operation is **idempotent** — only then does retrying define the error out of existence.
- **Red flag when:** retrying non-idempotent work — the pattern *manufactures* duplicate-effect errors instead of eliminating one. Idempotency first, retry second.

### Outbox
Write the state change and its outgoing event in one local transaction; relay the event afterward.
- **Hides:** the dual-write problem — "wrote the DB but lost the event" is [defined out of existence](./GLOSSARY.md#define-errors-out-of-existence).
- **Deep when:** state changes and published events must never diverge.
- **Red flag when:** used where no second system consumes the events — machinery for a consistency problem you don't have.

### Saga
A distributed operation as a sequence of local transactions, each with a compensating action.
- **Hides:** the absence of a distributed transaction.
- **Deep when:** the operation truly spans systems that cannot share a transaction boundary.
- **Red flag when:** the seam could be redrawn so one transaction covers the operation — every saga step needs a compensator, and compensators are where the untested paths live. Redraw before you compensate.

---

## Deliberate omissions

Interpreter, Servant, and the more ceremonial GoF entries are omitted on
purpose: this is a curated vocabulary, not an encyclopedia. A design that
reaches for an omitted pattern is not wrong — it is judged the same way
everything else is: by depth, by information hiding, and against the
[red flags](./GLOSSARY.md#design-red-flags).

---

*Sources: Gamma, Helm, Johnson, Vlissides, "Design Patterns" (1994); Fowler,
"Patterns of Enterprise Application Architecture" (2002); Hohpe & Woolf,
"Enterprise Integration Patterns" (2003); Nygard, "Release It!" (2007; 2nd ed.
2018). Framing and cautions: John Ousterhout, "A Philosophy of Software Design"
(2018; 2nd ed. 2021), esp. §19.5 on pattern over-application.*
