# LLM Workflows (V1 — legacy)

> **Legacy. Kept only as a changelog entry — not current guidance.**

This file used to describe an earlier multi-agent model. The active setup has
replaced it in two ways:

1. **Vertical-slice TDD, not all-tests-then-all-code.** The old model split
   test-writing and implementation across separate agents (`*-test-writer` +
   implementers) and wrote every test before any code. The current experts
   (`go-expert`, `python-expert`, `language-expert`) write one test, then its
   implementation, one behavior at a time. The all-tests-then-all-code split is
   now treated as an anti-pattern — see `dotfiles/claude/skills/tdd/SKILL.md`
   ("Anti-Pattern: Horizontal Slices").
2. **The `*-test-writer` agents no longer exist.** They were removed when the
   experts absorbed test-writing.

## Current workflows

- **Fast path** (small, well-scoped changes behind a stable interface):
  `dotfiles/claude/README.md` → `/implement`, `/implement-auto`,
  `/scout-and-plan`.
- **Heavy track** (work that creates or changes an interface): `WORKFLOW_V2.md`
  → `/wf` and the `wf-*` stage commands.
