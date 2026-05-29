---
name: llm-kb
description: Build and maintain a persistent, compounding personal knowledge base as interlinked markdown files. Use when the user wants to ingest sources, query their kb, lint for quality, or initialize a new kb project.
---

# LLM Knowledge Base

A pattern for building personal knowledge bases using LLMs. The LLM incrementally builds and maintains a persistent kb — a structured, interlinked collection of markdown files organized by domain folders. Knowledge is compiled once and kept current, not re-derived on every query.

## Architecture

The kb has three layers:

### 1. Raw Sources (`raw/`)
- Immutable source documents: articles, papers, notes, transcripts, images
- The LLM reads from these but NEVER modifies them
- This is the source of truth
- Images go in `raw/assets/`
- Meeting notes go in `raw/meetings/`

### 2. The KB (domain folders at repo root)
- LLM-generated and LLM-maintained markdown files organized by subject area
- Each domain folder has a `_overview.md` hub page linking to all pages in the folder
- The LLM owns this layer entirely — creates, updates, cross-references
- The user reads it; the LLM writes it

### 3. The Schema (`AGENTS.md`)
- Lives in the kb project root
- Tells the LLM how the kb is structured, conventions, and workflows
- Co-evolved by the user and LLM over time
- Domain-specific — tailored to the kb's subject matter

## Directory Structure

```
my-kb/
├── AGENTS.md              # Schema: conventions, structure, workflows
├── raw/                   # Immutable source documents
│   ├── assets/            # Downloaded images
│   ├── meetings/          # Meeting notes (YYYY-MM-DD-description.md)
│   └── ...                # Articles, papers, notes, etc.
├── index.md               # Master catalog of all pages
├── log.md                 # Chronological record of operations
├── overview.md            # High-level map of all knowledge areas
├── golang/                # One folder per domain
│   ├── _overview.md       # Hub page linking to all pages in the folder
│   ├── iterators.md
│   └── ...
├── docker/
├── architecture/
├── career/
└── .git/                  # Version history for free
```

### Layers

- **`raw/`** — Immutable source documents. The LLM reads from these but NEVER modifies them. This is the source of truth. Articles, papers, notes, transcripts, and images go here. Meeting notes go in `raw/meetings/`.
- **`AGENTS.md`** — The schema that tells the LLM how the kb is structured, what the conventions are, and what workflows to follow. Co-evolved by the user and LLM over time as you figure out what works for your domain.
- **Domain folders** (`golang/`, `docker/`, `architecture/`, `career/`, etc.) — LLM-generated and LLM-maintained pages organized by subject area. The LLM owns this layer entirely — creates, updates, and cross-references pages. The user reads them; the LLM writes them.
- **`_overview.md`** — Each domain folder has a hub page that links to all pages in the folder. This is the entry point for browsing a domain.
- **`index.md`** — Master catalog of every page in the kb, organized by domain. The LLM reads this first to find relevant pages when answering queries.
- **`log.md`** — Append-only chronological record of all operations (ingests, queries, lints, maintenance). Gives a timeline of the kb's evolution.
- **`overview.md`** — High-level synthesis of all knowledge areas. Updated when the big picture changes.
- **`.git/`** — The kb is a git repo. Version history, branching, and collaboration come for free.

### Links

All internal links use **Obsidian wikilinks**: `[[page name]]` or `[[folder/page|Display Name]]`. This enables Obsidian graph view, backlinks panel, and folder-agnostic linking. Never use markdown-style relative links.

## Core Operations

### Ingest

When the user adds a new source to `raw/` and asks to ingest it:

1. **Read** the source document thoroughly
2. **Discuss** key takeaways with the user — what's important, what to emphasize
3. **Identify** the appropriate domain folder (create a new one if needed)
4. **Create or update** pages in that domain folder with:
   - YAML frontmatter: `title`, `tags`, `date_created`, `date_updated`, `sources`
   - Key claims, findings, and insights
   - Notable quotes
   - Wikilinks to related pages across domains
5. **Update** existing pages across the kb with new information
   - Add new information with source attribution
   - Flag contradictions with existing claims
   - Strengthen or challenge the evolving synthesis
6. **Update** the domain's `_overview.md` hub page
7. **Update** `index.md` with the new page(s)
8. **Update** `overview.md` if the source changes the big picture
9. **Append** to `log.md`:
   ```markdown
   ## [YYYY-MM-DD] ingest | Source Title
   - Summary: One-line description
   - Pages created: list
   - Pages updated: list
   ```

A single source typically touches 10-15 pages across multiple domain folders.

### Query

When the user asks a question:

1. **Read** `index.md` to find relevant pages
2. **Read** the relevant pages (not raw sources — the kb IS the compiled knowledge)
3. **Synthesize** an answer with citations using wikilinks
4. **Evaluate** if the answer is worth keeping — if so, offer to file it:
   - Create a page in the appropriate domain folder
   - Update `_overview.md`, `index.md`
   - Append to `log.md`
5. If the kb lacks information to answer, identify the gap and suggest sources to find

### Lint

Periodic health check of the kb:

1. **Contradictions** — pages that make conflicting claims
2. **Stale claims** — information superseded by newer sources
3. **Orphan pages** — pages with no inbound wikilinks
4. **Missing pages** — concepts mentioned but lacking their own page
5. **Missing cross-references** — pages that should wikilink to each other
6. **Missing `_overview.md`** — domain folders without a hub page
7. **Broken wikilinks** — `[[links]]` that don't resolve to real pages
8. **Data gaps** — topics that could be enriched with additional sources
9. **Suggest** new questions to investigate and new sources to look for
10. **Append** lint results to `log.md`

## Page Conventions

### Frontmatter

Every page should have YAML frontmatter:

```yaml
---
title: Page Title
tags: [golang, error-handling]
date_created: YYYY-MM-DD
date_updated: YYYY-MM-DD
sources: [source-file.md]
---
```

### Cross-references

Use Obsidian wikilinks:

```markdown
See [[golang/error-handling|Go Error Handling]] for more context.
This contradicts findings in [[architecture/service-extraction]].
```

### Source Attribution

Always cite which source(s) support a claim:

```markdown
Go iterators use `iter.Seq` and `iter.Seq2` types ([[golang/iterators|source]]).
```

### Contradiction Handling

When new information conflicts with existing kb content:

```markdown
> **Contradiction:** Source A claims X, but Source B found Y. The discrepancy may be due to [reason].
```

## Guidelines

- The user curates sources, directs analysis, asks questions, and thinks about meaning
- The LLM handles ALL bookkeeping: summarizing, cross-referencing, filing, updating
- Never modify files in `raw/` — they are immutable source documents
- Always update `index.md` and `log.md` when making changes
- Always use Obsidian wikilinks — never markdown-style relative links
- Keep pages focused — one topic per page
- Prefer updating existing pages over creating duplicates
- Flag uncertainty and contradictions explicitly
- The kb should be browsable and useful without the LLM — it's a standalone artifact in Obsidian
