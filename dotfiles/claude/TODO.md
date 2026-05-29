# TODO

Drafts and open questions for the Claude config. Not loaded into Claude Code context.

## Document Archiving

**Status:** Draft. Needs more thought before re-enabling.

**Open question:** how to trigger this reliably?
- `Stop` / `SessionEnd` hook in `settings.json` — most reliable, runs automatically, but settings.json doesn't exist in dotfiles yet.
- Slash command — user-invoked, easy to forget.
- Instruction in `CLAUDE.md` — assumes I'll remember to do it during the conversation, which won't hold up.

**Original draft (from `CLAUDE.md`):**

> When markdown documents (`.md`) are created during a session, delegate to the **kb-curator** agent to ingest them into the knowledge base before the session ends:
>
> - KB repo: `~/Development/remote/github.com/invzn/kb`
> - Source files go in `raw/projects/{project-name}/` where `{project-name}` is the basename of the current project's git root
> - Delegate to kb-curator to: copy the source to `raw/projects/{project-name}/`, then ingest it (create/update domain pages, cross-references, index, log)
> - Only ingest markdown files that were **created** during this session, not files that were merely edited
> - Skip this if I explicitly say not to archive/save docs
> - Do not ingest files that are clearly not docs (e.g., agent definitions, prompt templates, config files, READMEs that ship with the project)
