# Glossary

---

## Design & Modularity

### Deep Module

A module whose **interface is small relative to the functionality it provides** — substantial capability hidden behind a simple interface. The opposite is a **shallow module**, whose interface is nearly as complex as its implementation, adding little abstraction value for its cognitive cost. The design goal is to maximise module depth, so callers can ignore implementation detail.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

### Design Red Flags

A set of recurring **warning signs** that a piece of code or a module is more complex than it should be — the book teaches you to recognise these rather than memorise rules. The recurring flags: **shallow module** (interface complex relative to what it hides — see [Shallow Module](#shallow-module)); **information leakage** (one design decision reflected in, and coupling, multiple modules); **temporal decomposition** (structure mirrors order of execution rather than knowledge); **overexposure** (the common case must learn rarely-needed features to use the interface); **pass-through method** (adds interface without adding functionality); **repetition** (a missing abstraction); **special-general mixture** (special-case code contaminating a general-purpose mechanism); **conjoined methods** (two pieces you cannot understand without reading both); **comment repeats code** / **implementation documentation contaminates interface**; **vague name** / **hard to pick name** / **hard to describe** (a fuzzy abstraction); and **nonobvious code**. In this workflow the interface-altitude flags are screened at the stage-4 critique gate, and the full set is screened by the standards review in the Implement stage.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

### Interface

The surface a module exposes to its callers — everything a caller must understand to use it, including the signatures it offers and the behavioural contract behind them. A **narrow** interface exposes little; a [Deep Module](#deep-module) pairs a narrow interface with substantial hidden implementation, whereas a [Shallow Module](#shallow-module) exposes nearly as much as it hides.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

### Shallow Module

A module whose **interface is nearly as complex as its implementation** — it adds little abstraction value while still imposing cognitive cost on callers. The opposite of a [Deep Module](#deep-module); the design goal is to avoid these by maximising module depth.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

---

## Process & Lifecycle

### Staged Delivery

A lifecycle model in which the up-front work — concept, requirements, architectural design — is done **once**, after which the system is built and released in successive usable increments rather than in one big delivery. Contrast with **Evolutionary Delivery**, where the plan itself adapts to feedback after each release; in Staged Delivery the stages are planned in advance and the architecture is assumed stable. It is the macro-shape this workflow follows (stages 1–4 up front, then one increment per module).

Source: Steve McConnell, *Rapid Development* (1996).

### Tracer Bullet

A minimal, end-to-end implementation that exercises the full path through a system — all the key [interfaces](#interface) wired together, even if each is only stubbed — to prove the pieces compose before any one of them is built out in depth. Like tracer ammunition, it shows you where you're aiming under real conditions, and you adjust from there. Here it is the skeleton increment: all interfaces stubbed plus one passing end-to-end test.

Source: Andrew Hunt & David Thomas, *The Pragmatic Programmer* (1999; 20th-anniversary ed. 2019).

### Walking Skeleton

A tiny end-to-end implementation that links together the main architectural components and runs through the real build, deploy, and test infrastructure — proving the system is wired together and automatable before any feature is fleshed out. Closely related to a [Tracer Bullet](#tracer-bullet); the distinction is one of emphasis — a tracer bullet stresses a thin slice through the *functional* layers, a walking skeleton stresses exercising the *deployment and test harness* end-to-end. Here the skeleton increment plays both roles.

Source: Alistair Cockburn (term origin); popularised by Steve Freeman & Nat Pryce, *Growing Object-Oriented Software, Guided by Tests* (2009).

---

## Work Management

### Task

A unit of work that needs to be completed within a certain deadline.
