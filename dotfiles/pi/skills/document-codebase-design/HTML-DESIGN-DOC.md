# HTML Design Doc Format

Single self-contained HTML file, committed to the repo (default `docs/architecture.html`). Tailwind and Mermaid via CDN. Mermaid handles graph-shaped diagrams; hand-built divs and inline SVG handle the editorial visuals (module map with depth, seam cards, domain snapshot).

Same visual register as [../improve-codebase-architecture/HTML-REPORT.md](../improve-codebase-architecture/HTML-REPORT.md) — editorial, not corporate-dashboard. Generous whitespace. One accent colour (indigo or emerald), red reserved for drift/leakage, amber reserved for warnings/ADR callouts.

## Scaffold

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>{{repo name}} — design</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>
      .seam { stroke-dasharray: 4 4; }
      .deep { background: linear-gradient(135deg, #0f172a, #1e293b); }
      .shallow { background: #f1f5f9; }
      .drift { stroke: #dc2626; }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-16">
      <header>...</header>
      <section id="module-map">...</section>
      <section id="seams">...</section>
      <section id="journeys">...</section>
      <section id="domain">...</section>
      <section id="decisions">...</section>
      <section id="drift">...</section>
    </main>
  </body>
</html>
```

## Editorial-keep blocks

Any block wrapped in HTML comments survives regeneration:

```html
<!-- editorial:keep -->
<p>Hand-written passage. Regenerator must copy this through verbatim.</p>
<!-- /editorial:keep -->
```

Before overwriting an existing file, extract every `editorial:keep` block from the old content and splice it back into the matching position in the new content. If the section it lived in is gone, append the block at the bottom of the closest surviving section, with an HTML comment noting the move.

## Header

Repo name as `font-serif text-3xl`. Below it, in `text-sm text-slate-500`: last updated date, one-line system summary lifted from `CONTEXT.md`. No introduction paragraph. No table of contents — the page is short enough to scroll.

Compact legend on the right: solid box = module, thick dark box = deep module, dashed line = seam, red edge = drift.

## Section 1 — Module map

The centrepiece. Hand-built when possible; Mermaid when the dependency graph is hairy.

### Hand-built version (preferred for ≤12 modules)

Position modules as absolutely-placed `<div>`s inside a `relative` container, ~480px tall. Arrows as inline SVG `<line>` or `<path>` over the container. Deep modules use `.deep` (dark gradient, white text). Shallow modules use `.shallow` (light grey). Most modules sit between.

Module label: `text-xs uppercase tracking-wider`. Below it, in `text-[10px] text-slate-500 font-mono`, the path (e.g. `internal/orders/`).

Group external dependencies (DB, queue, third-party APIs) into a single horizontal strip along the bottom edge, visually separated by a thin rule. Don't draw five database icons; draw one labelled "Postgres" with a dashed border.

### Mermaid version (fallback)

```html
<div class="rounded-lg border border-slate-200 bg-white p-6">
  <pre class="mermaid">
    flowchart TB
      Intake[Order Intake] --> Pricing[Pricing]
      Intake --> Inventory[Inventory]
      Pricing --> Catalog[Catalog]
      Inventory -.->|seam| Warehouse[(Warehouse API)]
      classDef deep fill:#0f172a,color:#fff,stroke:#0f172a;
      class Pricing deep
  </pre>
</div>
```

Use `classDef deep` to mark deep modules. Use dashed edges (`-.->`) for seam-crossing calls.

## Section 2 — Seam catalogue

Each real seam (≥2 adapters) as a card in a 2-column grid:

```html
<article class="rounded-lg border border-slate-200 bg-white p-5 space-y-3">
  <h3 class="font-serif text-lg">PriceSource</h3>
  <p class="text-sm text-slate-600">Where pricing comes from. One interface, swapped per environment.</p>
  <ul class="text-xs font-mono space-y-1">
    <li>→ <span class="text-slate-900">HTTPPriceSource</span> (prod)</li>
    <li>→ <span class="text-slate-900">FixturePriceSource</span> (tests)</li>
  </ul>
  <p class="text-xs uppercase tracking-wider text-slate-400">used by: Order Intake, Quoting</p>
</article>
```

No card for hypothetical seams (one adapter, no test double). If there are none, omit the section.

## Section 3 — Journeys

One Mermaid `sequenceDiagram` per journey. Frame each with a one-sentence caption above the diagram, in `text-sm text-slate-600 italic`.

```html
<div class="rounded-lg border border-slate-200 bg-white p-4">
  <p class="text-sm italic text-slate-600 mb-3">A customer submits an order; the system reserves inventory and quotes a price.</p>
  <pre class="mermaid">
    sequenceDiagram
      participant U as User
      participant I as Intake
      participant P as Pricing
      participant V as Inventory
      U->>I: POST /orders
      I->>P: quote(order)
      I->>V: reserve(order)
      V-->>I: reservation
      P-->>I: price
      I-->>U: 201 Created
  </pre>
</div>
```

1–3 journeys total. If you can't pick 3 that meaningfully differ, pick 1 and stop. Filler journeys dilute the doc.

## Section 4 — Domain snapshot

Two-column compact list of terms from `CONTEXT.md` — term in `font-mono text-sm`, one-line gloss in `text-sm text-slate-600`. Link to `CONTEXT.md` for full definitions. Do not paste full definitions inline — they will drift.

```html
<dl class="grid grid-cols-2 gap-x-8 gap-y-2 text-sm">
  <div><dt class="font-mono">Order</dt><dd class="text-slate-600">A customer's intent to buy, before fulfilment.</dd></div>
  <div><dt class="font-mono">Reservation</dt><dd class="text-slate-600">An inventory hold against an Order.</dd></div>
</dl>
```

## Section 5 — Decisions

ADR index. One row per ADR: number, title, one-line summary, link. Order newest-first.

```html
<ul class="divide-y divide-slate-200 text-sm">
  <li class="py-2 flex gap-4">
    <a href="../docs/adr/0007-price-source-seam.md" class="font-mono text-indigo-700">ADR-0007</a>
    <span class="flex-1">Pricing lives behind a seam — HTTP in prod, fixtures in tests.</span>
  </li>
</ul>
```

Don't summarise the ADRs in depth — that's what the ADRs themselves are for.

## Section 6 — Drift (conditional)

Only render if non-empty. Each item: one line, what disagrees with what, no prescription.

```html
<ul class="space-y-2 text-sm">
  <li class="border-l-4 border-red-500 pl-3">
    <span class="font-mono">internal/legacy/order_v1.go</span> still names "Order" what <code>CONTEXT.md</code> now calls "Quote."
  </li>
</ul>
```

Drift items are observations, not tasks. If the user wants tasks, they'll run the architecture-review skill.

## Style guidance

- Editorial, not corporate-dashboard. Generous whitespace.
- One accent (indigo or emerald). Red only for drift. Amber only for ADR conflicts.
- Diagrams ~320–480px tall. Module map can be wider; everything else fits in `max-w-5xl`.
- Module labels: `text-xs uppercase tracking-wider`. Paths: `font-mono text-[10px]`.
- No JS beyond the Tailwind CDN and the Mermaid ESM import. No interactivity, no collapsibles, no dark mode toggle.
- Mix Mermaid with hand-built visuals. Don't let every diagram look the same.

## Tone

Plain English captions. Architectural nouns from the glossary — *module, interface, seam, adapter, depth, leverage, locality.* Domain nouns from `CONTEXT.md`. Never "component," "service," "layer," "boundary."

Phrasings that fit:

- "Order Intake is the entry seam — one interface, two adapters."
- "Pricing is deep: most order logic concentrates here."
- "Inventory leverages the Warehouse seam; tests use the in-memory adapter."

Phrasings to avoid: "robust," "scalable," "well-architected," "clean," "best practices." None of those earn their place. Cut them.
