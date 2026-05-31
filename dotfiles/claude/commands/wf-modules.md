---
description: "Workflow V2 — Stage 4: decompose the design into deep modules behind narrow interfaces"
argument-hint: <path to design doc>
---
You are a senior tech lead running **Stage 4 (Module)** of Workflow V2.

Read the design doc at: $ARGUMENTS

Read `~/.claude/skills/tdd/language.md` (deep modules) and `~/.claude/skills/tdd/interface-design.md` (testability) before starting.

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may edit the design doc (markdown only) — do not touch code.

## Altitude of this stage — the placement rule
This stage owns **interfaces**, not behavior decisions (Stage 3) and not concrete tech (Stage 6):

> **Behavior → Design. Interface → Module. Tech → Implement.**

Decompose the Implementation Design into **deep modules** (Ousterhout: small interface, substantial hidden implementation — **not** architectural layers). Each module's spec **encodes the behavioral properties chosen in Design**. No concrete technologies in interfaces or specs.

## Sizing for reviewability (load-bearing)
Non-negotiable: every MR must be **reviewable in one sitting**. The lever is **module granularity, measured in behaviors**:

> If a module would produce an MR with more **behaviors** than I can review in one sitting, **split the module** — never split the MR.

A "behavior" is the TDD unit (one red→green cycle), so this is the same atom the implementation will use.

## Steps
1. Read the doc through the Implementation Design.
2. Converse with me to define the deep modules: for each, the **narrow interface** (signatures, not implementation) and a **spec** (the contract, including the behavioral properties from Design and the behaviors to test). Apply the behavior-count split rule.
3. Append a **## Modules** section: one subsection per module (interface + spec + rough behavior list). Backtracking is allowed — revise earlier sections in place if decomposition exposes a flaw, and note it.

## Tier (fixed here)
The module **count** now settles the track — record it in the doc so Planning and Implement follow it:
- **One deep module → V2-lite:** Planning produces a single task with **no MR #0** (nothing to parallelize); Implement builds it directly off the feature branch.
- **Multiple deep modules → full V2:** Planning leads with MR #0 to lock interfaces before parallel deepening.

## Critique gate (recommended before Stage 5)
Interface mistakes are the costliest. Recommend I run a critique pass before planning:
- `/design-review <feature>` (architect + DX), or
- `/grill-me <doc>` to stress-test the interfaces.
The tracer-bullet skeleton (Stage 5, MR #0) then empirically confirms the contracts compose.

## Output
- The **Modules** section (interfaces + specs)
- A recommendation to run the critique gate

**Next:** `/wf-plan <doc>` — wait for my go-ahead (ideally after the critique gate).
