---
name: ponytail-audit
description: Whole-repo audit for over-engineering. Like ponytail-review, but scans the entire codebase instead of a diff — a ranked list of what to delete, simplify, or replace with stdlib / native equivalents. Use when the request mentions "audit this codebase", "audit for over-engineering", "what can I delete from this repo", "find bloat", or "ponytail-audit". One-shot report; does not apply fixes.
license: MIT
---

# Ponytail Audit

Adapted from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (MIT). Host- and agent-agnostic.

`ponytail-review`, repo-wide. Scan the whole tree instead of a diff. Rank findings biggest cut first.

## Tags

Same as [ponytail-review](../ponytail-review/SKILL.md):

- **`delete:`** dead code, unused flexibility, speculative feature. Replacement: nothing.
- **`stdlib:`** hand-rolled thing the standard library ships. Name the function.
- **`native:`** dependency or code doing what the platform already does. Name the feature.
- **`yagni:`** abstraction with one implementation, config nobody sets, layer with one caller.
- **`shrink:`** same logic, fewer lines. Show the shorter form.

## Hunt

- Dependencies the stdlib or platform already ships.
- Single-implementation interfaces.
- Factories with one product.
- Wrappers that only delegate.
- Files exporting one thing.
- Dead flags and config.
- Hand-rolled stdlib.

## Output

One line per finding, ranked: `<tag> <what to cut>. <replacement>. [path]`.

End with `net: -<N> lines, -<M> deps possible.`

Nothing to cut: `Lean already. Ship.`

## Boundaries

Complexity only. Correctness bugs, security holes, and performance go to a normal review pass. Lists findings; applies nothing. One-shot.

"stop ponytail-audit" or "normal mode" reverts.
