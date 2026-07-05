# Environment Repository

This is a personal development environment configuration repo (dotfiles, scripts, and tools).

## Structure

- `dotfiles/` — Shell, editor, terminal, and window manager configs
  - `bashrc`, `bash/` — Bash configuration
  - `vimrc`, `vim/` — Vim configuration
  - `tmux.conf` — Tmux configuration
  - `config/nvim/` — Neovim (LazyVim-based) configuration
  - `config/ghostty/` — Ghostty terminal config
  - `config/aerospace/` — AeroSpace window manager config
  - `config/k9s/` — k9s Kubernetes UI config
  - `config/nix/` — Nix package manager config
- `scripts/` — Install and update scripts
  - `install.sh` — Copies dotfiles onto the local machine (reset-and-replace per category)
  - `update_repo.sh` — Copies local machine configs back into repo
- `nixflakes/` — Nix flake configurations
- `iterm2/` — iTerm2 themes and font patching
- `dotfiles/claude/` — Claude Code configuration (primary coding agent; see `dotfiles/claude/README.md`)
  - `agents/` — Subagent definitions (implementation experts, reviewers, recon)
  - `commands/` — Slash commands (`implement`, complexity-first SDLC `sdlc-*`, review, `kb-*`)
  - `skills/` — Skills (`tdd`, `grill-me`, `grill-with-docs`, `improve-codebase-architecture`, `llm-kb`)
  - `references/` — Style guides read by agents (e.g. `go-styleguide.md`)
  - `CLAUDE.md` — Global instructions applied to every project
- `dotfiles/pi/` — Pi coding agent configuration (predecessor to the claude config; still installable)
  - `agents/` — Sub-agent definitions (reviewer perspectives, scout, planner, worker)
  - `extensions/subagent/` — Sub-agent extension (index.ts, agents.ts)
  - `prompts/` — Workflow prompt templates (review, pr-review, kb-*, etc.)
  - `skills/llm-kb/` — LLM Knowledge Base skill for persistent knowledge bases
  - `settings.json` — Pi settings (no secrets)
- `dotfiles/mempalace/` — MemPalace configuration
  - `config.json` — MemPalace config (palace directory location)
  - `pi-to-transcript.py` — Converter script (pi JSONL sessions → transcripts)
- `brew_list.txt` — Historical Homebrew package list (legacy, not actively maintained)

## Conventions

- Configs are installed (copied) using `scripts/install.sh`
- Each config type has a `--flag` for selective install/update (e.g., `--bash`, `--nvim`, `--ghostty`)
- Neovim config uses LazyVim with Lua-based plugin management
- Keep scripts POSIX-compatible where possible; target macOS (zsh/bash)
- When adding new dotfile categories, follow the existing pattern:
  1. Add the config files under `dotfiles/`
  2. Add `--flag` handling to both `scripts/install.sh` and `scripts/update_repo.sh`
  3. Update the README.md structure section and usage examples

## Testing

- After modifying install/update scripts, verify with a dry run or test on a clean path
- For Neovim changes, run `nvim --headless "+Lazy sync" +qa` to verify plugin resolution

## Do Not

- Do not commit secrets, API keys, or tokens
- Do not modify `lazy-lock.json` manually — it is managed by LazyVim
