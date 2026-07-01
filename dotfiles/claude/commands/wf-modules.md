---
description: "LLM workflow — Stage 4: decompose the design into deep modules behind narrow interfaces"
argument-hint: <path to design doc>
---
You are the **lead agent** running **Stage 4 (Module)** of the LLM development workflow.

**Canonical spec (source of truth):** `~/.claude/references/llm-workflow/LLM_WORKFLOW.md` + `GLOSSARY.md`. Defer to it for anything unstated.

Read the design doc at: $ARGUMENTS

Read `~/.claude/skills/tdd/language.md` (deep modules) and `~/.claude/skills/tdd/interface-design.md` (testability) before starting.

Bash is read-only here (`git diff`, `git log`, `git show`, `git status`). You may edit the design doc (markdown only) — do not touch code.

## Altitude of this stage — the placement rule
This stage owns **interfaces**, not behavior decisions (Stage 3) and not concrete tech (Stage 6):

> **Behavior → Design. Interface → Module. Tech → Implement.**

Decompose the Implementation Design into **deep modules** (Ousterhout: small interface, substantial hidden implementation — **not** architectural layers). Each module's spec **encodes the behavioral properties chosen in Design**. No concrete technologies in interfaces or specs. If a signature reveals a Design-level behavioral statement was underspecified, that is a **backtrack to Design** — revise in place and re-run forward.

## Sizing for reviewability (load-bearing)
Non-negotiable: every MR must be **reviewable (comprehensible) in one sitting**. The lever is **module granularity, measured in behaviors**:

> If a module would produce an MR with more **behaviors** than I can review in one sitting, **split the module** — never split the MR.

A "behavior" is the TDD unit (one red→green cycle). **Splitting is cheap only when a natural internal sub-abstraction exists** — prefer that seam, so each half stays deep. **Depth wins:** if the only available split would expose an artificial interface and yield *shallow* modules, the module is irreducible — accept the larger MR and **flag it as the rare exception** rather than fabricating a seam to hit a size target.

## Steps
1. Read the doc through the Implementation Design.
2. Converse with me to define the deep modules: for each, the **narrow interface** (signatures, not implementation) and a **spec** (the contract, including the behavioral properties from Design and the behaviors to test). Apply the split rule above.
3. Append a **## Modules** section: one subsection per module (interface + spec + rough behavior list). Backtracking is allowed — revise earlier sections in place if decomposition exposes a flaw, and note it.

## Tier — second routing clock fires here (at this stage's exit)
You are now looking at the interface list, so this call is near-free. The skeleton/interface-lock machinery exists to prevent **interface drift between independently-built modules** — multiple modules committing to *shared* interfaces before those interfaces are validated. **The trigger is not raw module count.** Recommend, and record in the doc:

- **Lite** — no shared interfaces are committed before validation: a **single** deep module, *or several built strictly one-at-a-time*. Planning **skips the skeleton** (a wrong interface is corrected for free by backtracking, since nothing else is in flight).
- **Full** — **multiple** deep modules will commit to **shared** interfaces before validation (the usual case under concurrent construction). Planning leads with the skeleton to lock interfaces before parallel deepening.

I confirm or override the tier.

## Critique gate (recommended before Stage 5)
This is the **first of three layered interface checks** — the **analytical** one: *are these the right interfaces — deep, well-factored, hiding the right complexity?* It cannot catch "they don't actually compose" (nothing is wired yet — that is the skeleton's job). Interface mistakes are the costliest to undo. Recommend I run:
- `/design-review <feature>` (architect + DX), or
- `/grill-me <doc>` to stress-test the interfaces.

## Output
- The **Modules** section (interfaces + specs)
- The recommended **tier** (Lite / Full) and why
- A recommendation to run the critique gate

**Gate: critique.** **Next:** `/wf-plan <doc>` — wait for my go-ahead (ideally after the critique gate).
