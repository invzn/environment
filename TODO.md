# TODO

Remaining issues from the multi-perspective code review.

## P1 — Should Fix

- [ ] **Subagent temp file cleanup race** — If the process is `SIGKILL`ed, orphaned temp files with system prompts persist in `/tmp`. *(Upstream subagent extension — not our code.)*
- [ ] **`--vim` flag installs nvim** — Both `install.sh` and `update_repo.sh` map `--vim` to `nvim_flag="true"`. The actual vim install is commented out. Either remove `--vim` or restore vim support.
- [ ] **Copy vs symlink mismatch** — `AGENTS.md` says "configs are installed via symlinks" but scripts use `cp`. Either switch to `ln -sf` or correct the docs.
- [ ] **Missing `--ghostty` flag parser** — `install_ghostty`/`update_ghostty` functions exist and help text mentions `--ghostty`, but there's no `--ghostty)` case in the `while` loop of either script.

## P2 — Consider

- [ ] **Hardcoded model versions** — Agents use `model: claude-sonnet-4-5` / `claude-haiku-4-5`. Will break when model versions change. Consider using patterns or making the model configurable.
- [ ] **Undocumented concurrency limits** — Subagent `MAX_CONCURRENCY=4` and `MAX_PARALLEL_TASKS=8` aren't surfaced to users. *(Upstream subagent extension — not our code.)*
- [ ] **README and AGENTS.md out of sync** — README structure tree doesn't include `dotfiles/pi/` or `AGENTS.md`.
- [ ] **Prompts don't list available agents** — Templates like `review.md` hardcode agent names with no reference for new users.
- [ ] **Missing `--k9s` and `--nix` flags** — `dotfiles/config/k9s/` and `dotfiles/config/nix/` exist but have no install/update support.
