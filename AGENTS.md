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
  - `install.sh` — Symlinks dotfiles to local machine
  - `update_repo.sh` — Copies local machine configs back into repo
- `nixflakes/` — Nix flake configurations
- `iterm2/` — iTerm2 themes and font patching
- `dotfiles/pi/` — Pi coding agent configuration
  - `agents/` — Sub-agent definitions (reviewer perspectives, scout, planner, worker)
  - `extensions/subagent/` — Sub-agent extension (index.ts, agents.ts)
  - `prompts/` — Workflow prompt templates (review, pr-review, etc.)
  - `settings.json` — Pi settings (no secrets)
- `brew_list.txt` — Historical Homebrew package list (legacy, not actively maintained)

## Conventions

- Configs are installed via symlinks using `scripts/install.sh`
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
