# Claude Code Setup

My Claude Code configuration: subagents, slash commands, skills, references, and global instructions. Everything here installs into `~/.claude/` via `scripts/install.sh --claude`.

The setup is built around four cross-cutting ideas: **vertical-slice TDD**, **multi-perspective review**, a **persistent knowledge base (KB)**, and **grilling** plans before building them. Two implementation tracks sit on top: a lightweight **fast path** (`implement`) and the **complexity-first SDLC** (`sdlc`), a design-first track built on *A Philosophy of Software Design*.

## Layout

| Dir / file | What it holds |
|---|---|
| `CLAUDE.md` | Global instructions applied to every project (safety + interaction style) |
| `agents/` | 13 subagent definitions (experts, reviewers, recon) |
| `commands/` | 19 slash commands across four families |
| `skills/` | 5 skills (TDD, grilling, architecture, KB) |
| `references/` | Style guides agents read at runtime |
| `TODO.md` | Drafts/open questions; **not** loaded into context, **not** installed |

Installed via `scripts/install.sh --claude`, which **resets and replaces** `~/.claude/{agents,commands,references,skills}` and copies `CLAUDE.md`. It does **not** manage `settings.json`, `keybindings.json`, or `projects/` (memory). `update_repo.sh --claude` pulls local edits back into the repo.

## Global instructions (`CLAUDE.md`)

- **Safety:** file changes only inside git repositories; read-only everywhere else. Git is read-only (`diff`/`log`/`show`/`status`) — never commit, push, or alter history/tree unless explicitly asked.
- **Interaction style:** direct, critical, honest. Challenge assumptions, advocate better approaches, don't default to agreement or over-validate.

## Agents

Models are tiered: `repo-expert` runs on **haiku** (fast/cheap recon); all other agents on **sonnet**; the main thread (typically **opus**) orchestrates and delegates.

**Implementation experts** (vertical-slice TDD — write tests *and* implementation, one behavior at a time):
- `go-expert` — Go, follows the Go Style Guide (`references/go-styleguide.md`)
- `python-expert` — Python, follows the Google Python Style Guide
- `language-expert` — any other language, idiomatic conventions

**Reviewers:**
- `reviewer` — general quality + security
- `go-standards-reviewer` / `python-standards-reviewer` — style-guide conformance
- `architect-reviewer` — design, coupling, extensibility
- `security-reviewer` — vulnerabilities, auth, injection, secrets
- `performance-reviewer` — bottlenecks, scaling, leaks
- `dx-reviewer` — clarity, naming, docs, onboarding
- `red-flag-auditor` — adversarial complexity audit against the *Philosophy of Software Design* red flags (the SDLC's stage-3 contract screen and stage-5 gate)

**Recon & support:**
- `repo-expert` — maps a repo's architecture and locates relevant code for handoff
- `kb-curator` — ingests/maintains the LLM knowledge base

## Commands

**Implementation & planning**
- `scout-and-plan` — repo-expert recon + a prioritized TDD plan (no code)
- `implement` — full TDD workflow, **step mode** (pauses for approval between phases)
- `implement-auto` — same workflow, **auto mode** (runs end to end)

**Complexity-first SDLC — the heavy track** (design-first; see [`PHILOSOPHY_SDLC.md`](../../philosophy_sdlc/PHILOSOPHY_SDLC.md))
- `sdlc` — orchestrator; runs all six stages with gates, holding the strategic checkpoints against the model's tactical defaults
- `sdlc-frame` → `sdlc-design` → `sdlc-interface` → `sdlc-implement` → `sdlc-audit` → `sdlc-integrate` — the six stages, each filling one section of a per-change design record ([`DESIGN-RECORD.md`](../../philosophy_sdlc/DESIGN-RECORD.md))

**Review**
- `review` — security + performance + architecture + DX in parallel
- `pr-review` — the four perspectives on the git diff
- `design-review` — repo-expert + architect + DX
- `security-review` — repo-expert + security-reviewer

**Knowledge base** (`kb-*`)
- `kb-init`, `kb-ingest`, `kb-query`, `kb-lint`, `kb-maintain`, `kb-meeting` — initialize, ingest sources, query, health-check, maintain, and ingest meeting notes

## Skills

- `tdd` — red-green-refactor methodology. Sub-docs: `language.md` (deep modules), `interface-design.md`, `deepening.md`, `refactoring.md`, `mocking.md`, `tests.md`
- `grill-me` — relentless interview to stress-test a plan and resolve its decision tree
- `grill-with-docs` — grilling that also challenges a plan against the project's domain model and updates `CONTEXT.md` / ADRs inline
- `improve-codebase-architecture` — find deepening/refactoring opportunities, informed by the KB glossary and ADRs
- `llm-kb` — build and maintain the persistent, interlinked-markdown knowledge base

## References

- `go-styleguide.md` — Go conventions, read by `go-expert` and `go-standards-reviewer`

## How it composes

Routing happens at the SDLC's stage-1 gate, derived from the framing itself: if there is **no knowledge worth hiding** (no deep module boundary to place), the work takes the fast path; the human decides.

**Fast path** — no deep module (shallow changes, trivial interface tweaks, behavior behind a stable interface, mechanical refactors regardless of size):
`scout-and-plan` (plan) → `implement` / `implement-auto`. The orchestrating thread delegates the TDD loop to the matching language expert, then fans out to reviewers, then applies fixes.

**Heavy track (complexity-first SDLC)** — work that introduces deep modules:
`sdlc` walks frame → design-it-twice → interface → implement → audit → integrate, filling a per-change design record with every gate verdict written down. Stage 2 spawns *independent* agents so the alternatives aren't anchored on each other; stage 3 writes the interface comment before any code; stage 4 implements under standing instructions (pull complexity downward, define errors out of existence, tests lock the settled contract); stage 5's `red-flag-auditor` blocks the merge on any un-refuted flag; stage 6 rejects the smallest-possible-change and settles the complexity budget. Full rationale in `PHILOSOPHY_SDLC.md`.

**Review flows** — `review` / `pr-review` / `design-review` / `security-review` are thin orchestrators that fan work out to the reviewer agents in parallel and synthesize their findings.

**KB backbone** — `llm-kb` (skill) + `kb-curator` (agent) + `kb-*` (commands) maintain a persistent knowledge base. `grill-with-docs` and `improve-codebase-architecture` read from it (glossary, ADRs) so design work stays consistent with documented decisions.

## Observations

Findings from reviewing the setup — gaps, drift, and rough edges worth addressing:

1. **`AGENTS.md` (repo root) is stale.** It still documents the *pi* coding agent under `dotfiles/pi/`, but the configs were migrated pi → claude and it was never updated. It now misdescribes the active setup.
2. ~~**`WORKFLOW.md` is V1, `WORKFLOW_V2.md` is current** — and nothing labels the older one as superseded.~~ **Resolved twice** — the V1/V2 prose docs were replaced by `llm_workflow/LLM_WORKFLOW.md`, which has itself been retired in favor of the complexity-first SDLC: the canonical, harness-agnostic spec is now [`../../philosophy_sdlc/PHILOSOPHY_SDLC.md`](../../philosophy_sdlc/PHILOSOPHY_SDLC.md), and the `sdlc-*` commands are the binding that derives from it. The old spec is kept (marked retired) for the machinery the successor deliberately omits — depth routing tiers, the tracer-bullet skeleton / interface lock, MR sizing and batching.
3. **No `settings.json` in the repo.** Hooks and harness settings aren't version-controlled, which is exactly what blocks the document-archiving automation drafted in `TODO.md` (a `Stop`/`SessionEnd` hook has nowhere to live). Checking in a `settings.json` would unblock it.
4. **Python style guide isn't pinned.** Go has a checked-in `references/go-styleguide.md`; Python relies on the model's memory of the Google guide. Asymmetric — a `references/python-styleguide.md` would make Python conformance as reproducible as Go's.
5. **Two grilling skills overlap.** `grill-me` and `grill-with-docs` need a crisp "use X when…" line, or they'll be picked inconsistently.
6. **Reviewer overlap.** `reviewer` claims "quality + security" while a dedicated `security-reviewer` exists; clarify whether `reviewer` should stay out of security to avoid redundant findings.
