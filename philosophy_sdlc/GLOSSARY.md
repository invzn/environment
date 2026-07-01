# Glossary

Terminology for the [complexity-first SDLC](./PHILOSOPHY_SDLC.md). This glossary
is self-contained: it defines every term the specification cites, including the
core *A Philosophy of Software Design* vocabulary, so the workflow stands on its
own.

---

## Design & Modularity

### Classitis

The mistaken belief that classes and methods should be **small**, which leads to a proliferation of **shallow modules** (see [Shallow Module](#shallow-module)) and the interface boilerplate of stitching them together. Length is not the enemy; shallowness is. A characteristic failure mode of LLM-generated code, which tends to over-decompose into many tiny units and mistake *small* for *simple*.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

### Complexity

Anything about a system's structure that makes it **hard to understand or modify**. It is *incremental* — it accretes from many small, individually-reasonable choices, which is what makes it hard to fight. It surfaces as three symptoms: **change amplification** (a simple change requires edits in many places), **cognitive load** (how much a developer must know to make a change), and **unknown unknowns** (it is not obvious *which* code must change, or what must be known to change it safely — the worst of the three). Reducing complexity, measured by these symptoms, is the goal of the discipline.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

### Complexity Budget

An explicit, up-front statement of what is allowed to get **more complex** and what must stay simple as a change is made — set before any code, so complexity is spent deliberately rather than accreted silently. Not a term from Ousterhout; it is this workflow's framing of his **strategic-investment** idea (the continuous ~10–20% design tax), turned into the stage-1 checkpoint.

Source: this workflow, after John Ousterhout, *A Philosophy of Software Design*.

### Deep Module

A module whose **interface is small relative to the functionality it provides** — substantial capability hidden behind a simple interface. The opposite is a **shallow module**, whose interface is nearly as complex as its implementation, adding little abstraction value for its cognitive cost. The design goal is to maximise module depth, so callers can ignore implementation detail.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

### Define Errors Out of Existence

A technique for handling exceptions by **designing the semantics so the error cannot occur** in the first place, rather than detecting and propagating it — e.g. clamping an out-of-range substring index, or making an `unset`/delete operation succeed on an already-absent key. It minimises the number of places that must deal with an error by pulling that complexity into the module's own definition. Used as a standing implementation instruction at stage 4, because the LLM's default is to raise exceptions the callers must then handle.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

### Design It Twice

The practice of considering **two or more radically different designs** for any nontrivial module before committing to one — not minor variations, genuinely different approaches. Even experienced designers produce markedly better results when forced to compare alternatives. Here it is a load-bearing stage (stage 2) rather than a nicety, because an LLM can generate divergent designs almost for free.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

### Design Red Flags

A set of recurring **warning signs** that a piece of code or a module is more complex than it should be — the book teaches you to recognise these rather than memorise rules. The recurring flags: **shallow module** (interface complex relative to what it hides — see [Shallow Module](#shallow-module)); **information leakage** (one design decision reflected in, and coupling, multiple modules); **temporal decomposition** (structure mirrors order of execution rather than knowledge); **overexposure** (the common case must learn rarely-needed features to use the interface); **pass-through method** (adds interface without adding functionality); **repetition** (a missing abstraction); **special-general mixture** (special-case code contaminating a general-purpose mechanism); **conjoined methods** (two pieces you cannot understand without reading both); **comment repeats code** / **implementation documentation contaminates interface**; **vague name** / **hard to pick name** / **hard to describe** (a fuzzy abstraction); and **nonobvious code**. In this workflow the interface-altitude flags are screened at the stage-3 critique gate, and the full set is screened by the adversarial red-flag audit at stage 5.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

### Interface

The surface a module exposes to its callers — everything a caller must understand to use it, including the signatures it offers and the behavioural contract behind them. A **narrow** interface exposes little; a [Deep Module](#deep-module) pairs a narrow interface with substantial hidden implementation, whereas a [Shallow Module](#shallow-module) exposes nearly as much as it hides.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

### Pull Complexity Downward

The principle that, faced with unavoidable complexity, it is better for the **module's developer** to absorb it than to expose it to the module's **many callers** — handle it inside the implementation rather than reflecting it in the interface. One developer suffers so many users don't. Stated as a standing implementation instruction at stage 4, because the LLM's default is to push complexity *up* by exposing configuration and edge cases through the interface.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

### Shallow Module

A module whose **interface is nearly as complex as its implementation** — it adds little abstraction value while still imposing cognitive cost on callers. The opposite of a [Deep Module](#deep-module); the design goal is to avoid these by maximising module depth.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).

---

## Process & Mindset

### Design Record

The single per-change markdown file that **accumulates the six stages' outputs** — strategic intent, candidate designs, interface contract, implementation trail, red-flag audit table, and integration verdict — with every gate verdict recorded explicitly and revisions made in place on backtrack. It is the workflow's memory: the artifact each stage reads as its input contract and writes as its output. Its concrete format is specified in [DESIGN-RECORD.md](./DESIGN-RECORD.md). Not a term from Ousterhout; it is this workflow's mechanism for making non-negotiable 2 auditable — a strategic step that isn't recorded in it is assumed not to have happened.

Source: this workflow, after John Ousterhout, *A Philosophy of Software Design*.

### Tactical vs. Strategic Programming

Two opposed working styles. **Tactical** programming treats getting code *working* as the goal; complexity accretes one expedient choice at a time. **Strategic** programming treats working code as necessary but insufficient — the goal is a *great design* — and pays a continuous ~10–20% investment to keep it. The premise of this workflow is that an LLM is a tactical-programming engine by default, so strategy must be deliberately imposed at every stage.

Source: John Ousterhout, *A Philosophy of Software Design* (2018; 2nd ed. 2021).
