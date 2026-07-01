# LLM Workflows (V1 — legacy)

> **Legacy (V1). Kept for reference, not current guidance.** This describes an
> earlier model that the active setup has since replaced in two ways:
> 1. It splits test-writing and implementation across separate agents
>    (`*-test-writer` + implementers) and writes all tests before any code.
>    The current experts do **vertical-slice TDD** — the same agent writes one
>    test, then its implementation, one behavior at a time. The
>    all-tests-then-all-code split is now treated as an anti-pattern
>    (see `dotfiles/claude/skills/tdd/SKILL.md`).
> 2. The `*-test-writer` agents no longer exist.
>
> **Current workflows:** fast path → `dotfiles/claude/README.md`
> (`implement` / `implement-auto`); heavy track → `WORKFLOW_V2.md` (`wf`).

## Pipeline

```
Requirements
    │
    ▼
┌───────────┐     ┌──────────────┐
│ Tech Lead │────▶│ Repo Expert  │  (discovery — per repo, uses Haiku for speed)
└───────────┘     └──────────────┘
    │
    ▼
  Planning (Tech Lead documents functions + order)
    │
    ▼
┌──────────────────────┐
│ Tests                │
│  ┌──────────────┐    │
│  │ Go Test      │    │  (write tests from requirements only)
│  │ Python Test  │    │
│  │ Lang Test    │    │  (fallback for other languages)
│  └──────────────┘    │
└──────────────────────┘
    │
    ▼
┌──────────────────────┐
│ Implementation       │
│  ┌──────────────┐    │
│  │ Go Expert    │    │  (implement against tests, no test modifications)
│  │ Python Expert│    │
│  │ Lang Expert  │    │  (fallback for other languages)
│  └──────────────┘    │
└──────────────────────┘
    │
    ▼
┌───────────────────┐
│ Review            │
│  • reviewer       │  (general quality)
│  • go/python-     │  (language standards)
│    standards-     │
│    reviewer       │
│  • architect-     │  (design, optional)
│  • security-      │  (auth/input, optional)
│  • performance-   │  (hot paths, optional)
│  • dx-reviewer    │  (DX, optional)
└───────────────────┘
    │
    ▼
  Fix cycle (if needed, back to language expert)
```

## Agents

For all agents:
- Don't make changes outside of a git repository
- Only use read-only git commands (except language experts during implementation)

### Tech Lead

Orchestrates the full lifecycle. Does NOT modify code directly.

1. Reads requirements
2. Delegates to **repo-expert** to identify relevant repos, files, and functions (one invocation per repo)
3. Documents a concrete implementation plan — functions to add/modify with signatures, dependencies, and order
4. For each function (TDD):
   1. Delegates to the appropriate language expert to write unit tests first
   2. Delegates to the same expert to implement against those tests
5. Delegates to reviewers for quality checks
6. Delegates fixes back to language experts if reviewers find issues

### Repo Expert

Replaces the old scout. A senior engineer and subject matter expert in a specific git repository. Uses Haiku for speed.

- Maps repository structure and architecture
- Locates relevant code with exact file paths and line ranges
- Identifies functions to create or update
- Documents existing test patterns and conventions
- Returns structured context for handoff (the receiving agent has NOT seen the files)

Thoroughness levels: quick, medium (default), thorough.

### Test Writers

Write unit tests from requirements and function signatures only. They must NOT read existing implementations. This enforces real TDD — tests define the behavior.

| Agent | Language |
|-------|----------|
| **go-test-writer** | Go — table-driven tests, `t.Run`, `cmp.Diff` |
| **python-test-writer** | Python — pytest, parametrize, `unittest.mock` |
| **language-test-writer** | Any language — matches project conventions |

### Implementers

Implement production code against existing tests. They must NOT modify test files.

| Agent | Language |
|-------|----------|
| **go-expert** | Go — Google Go Style Guide, Effective Go |
| **python-expert** | Python — Google Python Style Guide |
| **language-expert** | Any language — idiomatic conventions |

## Reviewers

Invoked by the Tech Lead after implementation. All are read-only.

| Reviewer | When to invoke |
|----------|---------------|
| **reviewer** | Always — general quality, bugs, code smells |
| **go-standards-reviewer** | Go changes — Google Go Style Guide compliance |
| **python-standards-reviewer** | Python changes — Google Python Style Guide compliance |
| **architect-reviewer** | Design/structural changes — coupling, APIs, extensibility |
| **security-reviewer** | Auth, input handling, API changes — vulnerabilities, secrets |
| **performance-reviewer** | Hot paths, data-heavy changes — bottlenecks, memory, scaling |
| **dx-reviewer** | Public APIs, onboarding code — clarity, error messages, docs |

## Other Agents

| Agent | Purpose |
|-------|---------|
| **kb-curator** | Manages LLM Knowledge Base wikis — ingest, query, lint, maintain |
