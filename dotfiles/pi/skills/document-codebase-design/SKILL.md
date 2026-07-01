---
name: document-codebase-design
description: Create or update a single-file, visual HTML design document for a codebase — module map, seams, key journeys, and domain snapshot. Informed by CONTEXT.md and docs/adr/. Use when the user wants to document how the codebase fits together, create or refresh an architecture overview, onboard newcomers, or produce a living design doc.
---

# Document Codebase Design

Produce a **living design document** for the codebase as a single self-contained HTML file in the repo. The aim is onboarding speed and AI-navigability: a newcomer (human or agent) should be able to open one file and understand the shape of the system in five minutes.

This is the **descriptive** counterpart to [improve-codebase-architecture](../improve-codebase-architecture/SKILL.md). That skill proposes *deepenings* into a tmp report; this skill describes *what is*, in the repo, with the same vocabulary.

## Glossary

Use these terms exactly. Full definitions in [../improve-codebase-architecture/LANGUAGE.md](../improve-codebase-architecture/LANGUAGE.md).

- **Module** — anything with an interface and an implementation.
- **Interface** — everything a caller must know to use the module.
- **Implementation** — the code inside.
- **Depth / deep / shallow** — leverage at the interface.
- **Seam** — where an interface lives; somewhere behaviour can be altered without editing in place.
- **Adapter** — a concrete thing satisfying an interface at a seam.
- **Leverage**, **locality** — what callers and maintainers get from depth.

Domain nouns come from `CONTEXT.md`. Architecture nouns come from the glossary above. Never substitute "component," "service," "layer," "boundary."

## Output location

Default path: `docs/architecture.html`.

- If the file exists, **read it first** to learn the existing structure, then rewrite. Preserve any block wrapped in `<!-- editorial:keep -->` … `<!-- /editorial:keep -->` verbatim — those are hand-written passages the user wants to survive regeneration.
- If `docs/` doesn't exist, create it.
- If the user has specified another location (e.g. `ARCHITECTURE.html` at the root, or `docs/design/index.html`), use that.

Tell the user the absolute path after writing. Do **not** open it in a browser automatically — this lives in the repo, the user will view it however they want.

## Process

### 1. Orient

Read these first, in order, before opening any source file:

1. `CONTEXT.md` (or `docs/CONTEXT.md`) — the domain language. Every diagram label must be sourceable from this file or earned during exploration.
2. `docs/adr/*.md` — decisions you must respect and reference. ADRs are load-bearing; if the doc contradicts one, the doc is wrong.
3. `README.md`, `AGENTS.md`, top-level `package.json` / `Cargo.toml` / `go.mod` / equivalent — to confirm the project's stated shape.
4. Any existing `docs/architecture.html` — to learn the prior structure and find `editorial:keep` blocks.

If `CONTEXT.md` is missing, **stop and ask** whether to scaffold one first (see [../grill-with-docs/CONTEXT-FORMAT.md](../grill-with-docs/CONTEXT-FORMAT.md)). A design doc without a domain glossary will drift into corporate-dashboard prose within one revision.

### 2. Explore

Use the Agent tool with `subagent_type=Explore` (or walk the tree directly for small repos) to map:

- **Top-level modules** — the units a newcomer needs to know exist. Not every file. Aim for 5–12 boxes on the module map.
- **Seams** — places with ≥2 adapters, or a single adapter with a clearly named interface. One adapter = note as a *hypothetical seam* only if the user has flagged it; otherwise leave it out.
- **Key journeys** — 1–3 paths through the system that represent the bulk of what it does (e.g. "user submits an order," "scheduled job reconciles inventory"). Pick journeys that touch multiple modules — single-module journeys aren't worth a sequence diagram.
- **External dependencies** — databases, queues, third-party APIs. Group, don't enumerate.

Note where the code's structure disagrees with `CONTEXT.md`. Surface it in the doc as a flagged section ("Drift") rather than silently papering over it.

### 3. Write the HTML

Single file. Tailwind via CDN, Mermaid via CDN, hand-built SVG where Mermaid would look generic. See [HTML-DESIGN-DOC.md](HTML-DESIGN-DOC.md) for the full scaffold, section patterns, and diagram guidance.

Sections, in order:

1. **Header** — repo name, last updated (today's date), one-line system summary lifted from `CONTEXT.md`.
2. **Module map** — the centrepiece diagram. Boxes for modules, edges for dependencies. Deep modules drawn thicker/darker. This is what people will screenshot.
3. **Seam catalogue** — each real seam as a card: interface name, adapters, where it's used. Sparse prose.
4. **Journeys** — one Mermaid sequence diagram per key journey, with a one-sentence framing.
5. **Domain snapshot** — the `CONTEXT.md` glossary rendered as a compact two-column list. Link out, don't duplicate definitions in full.
6. **Decisions** — index of ADRs with one-line summaries, linking to `docs/adr/`.
7. **Drift** (only if non-empty) — places where the code disagrees with `CONTEXT.md` or an ADR. One line each. No prescriptions — that's the architecture-review skill's job.

Skip any section that would be empty. Better to have five strong sections than seven with filler.

### 4. Hand off

After writing, report:

- Absolute path to the file.
- Which sections you populated and which you skipped (and why).
- Any `editorial:keep` blocks you preserved.
- Any drift you flagged.

Then ask: **"Which section would you like to refine first?"** Don't volunteer further changes — this is a doc the user co-owns.

## Refinement loop

When the user picks a section:

- **Module map looks wrong?** Walk the disagreement — is the diagram wrong, or is the code shallower/deeper than the user remembers? If the latter, note it as a candidate for `improve-codebase-architecture` rather than fixing it here.
- **Naming a module after a concept not in `CONTEXT.md`?** Add the term to `CONTEXT.md` inline (see [../grill-with-docs/CONTEXT-FORMAT.md](../grill-with-docs/CONTEXT-FORMAT.md)), then regenerate the doc.
- **User wants a section that doesn't fit the template?** Add it, but justify the addition in glossary terms. If it can't be justified, it probably belongs in a README or an ADR, not here.
- **User wants prose preserved across regenerations?** Wrap it in `<!-- editorial:keep --> … <!-- /editorial:keep -->`.

## Non-goals

- **Not a refactor proposal.** No before/after diagrams. No "deepening opportunities." Send those to `improve-codebase-architecture`.
- **Not exhaustive.** Every file does not need a box. If a module isn't load-bearing for understanding, leave it out.
- **Not narrative.** Diagrams carry the doc. Prose is captions.
