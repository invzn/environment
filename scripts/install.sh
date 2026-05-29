#!/bin/sh
set -e

repo_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
repo_dotfiles_dir="$repo_dir/dotfiles"
repo_bash_dir="$repo_dotfiles_dir/bash"
repo_vim_dir="$repo_dotfiles_dir/vim"
repo_nvim_dir="$repo_dotfiles_dir/config/nvim"
repo_ghostty_dir="$repo_dotfiles_dir/config/ghostty"
repo_aerospace_dir="$repo_dotfiles_dir/config/aerospace"
repo_pi_dir="$repo_dotfiles_dir/pi"
repo_claude_dir="$repo_dotfiles_dir/claude"
repo_mempalace_dir="$repo_dotfiles_dir/mempalace"

xdg_config_dir=".config"
bash_dir=".bash"
vim_dir=".vim"
nvim_dir="$xdg_config_dir/nvim"
ghostty_dir="$xdg_config_dir/ghostty"
aerospace_dir="$xdg_config_dir/aerospace"
pi_dir=".pi/agent"
claude_dir=".claude"

reset_dir () {
  # Validate the target is a subdirectory of the install dir
  case "$1" in
    "$install_dir"/*)
      ;;
    *)
      echo "Error: reset_dir refusing to operate on '$1' (not under install dir '$install_dir')" >&2
      return 1
      ;;
  esac

  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  elif [ -n "$(ls -A "$1" 2>/dev/null)" ]; then
    rm -rf "$1"/*
  fi
}

setup_xdg_config () {
  if [ ! -d "$1/$xdg_config_dir" ]; then
    mkdir -p "$1/$xdg_config_dir"
  fi
}

install_bash () {
  if [ "$(uname -s)" == "Darwin" ]; then
    cp "$repo_dotfiles_dir/bashrc" "$1/.bash_profile"
  else
    cp "$repo_dotfiles_dir/bashrc" "$1/.bashrc"
  fi
  reset_dir "$1/$bash_dir"
  cp -r "$repo_bash_dir"/. "$1/$bash_dir/"
}

install_tmux () {
  cp "$repo_dotfiles_dir/tmux.conf" "$1/.tmux.conf"
}

install_vim () {
  cp "$repo_dotfiles_dir/vimrc" "$1/.vimrc"
  reset_dir "$1/$vim_dir"
  cp -r "$repo_vim_dir"/. "$1/$vim_dir/"
}

install_nvim () {
  setup_xdg_config "$1"

  reset_dir "$1/$nvim_dir"
  cp -r "$repo_nvim_dir"/. "$1/$nvim_dir/"
}

install_ghostty () {
  setup_xdg_config "$1"

  reset_dir "$1/$ghostty_dir"
  cp -r "$repo_ghostty_dir"/. "$1/$ghostty_dir/"
}

install_aerospace () {
  if [ "$(uname -s)" == "Darwin" ]; then
    setup_xdg_config "$1"

    reset_dir "$1/$aerospace_dir"
    cp -r "$repo_aerospace_dir"/. "$1/$aerospace_dir/"
  fi
}

install_pi () {
  if [ ! -d "$1/$pi_dir" ]; then
    mkdir -p "$1/$pi_dir"
  fi

  # agents
  if [ -d "$repo_pi_dir/agents" ]; then
    reset_dir "$1/$pi_dir/agents"
    cp -r "$repo_pi_dir/agents"/. "$1/$pi_dir/agents/"
  fi

  # extensions
  if [ -d "$repo_pi_dir/extensions" ]; then
    reset_dir "$1/$pi_dir/extensions"
    cp -r "$repo_pi_dir/extensions"/. "$1/$pi_dir/extensions/"
  fi

  # prompts
  if [ -d "$repo_pi_dir/prompts" ]; then
    reset_dir "$1/$pi_dir/prompts"
    cp -r "$repo_pi_dir/prompts"/. "$1/$pi_dir/prompts/"
  fi

  # references
  if [ -d "$repo_pi_dir/references" ]; then
    reset_dir "$1/$pi_dir/references"
    cp -r "$repo_pi_dir/references"/. "$1/$pi_dir/references/"
  fi

  # skills
  if [ -d "$repo_pi_dir/skills" ]; then
    reset_dir "$1/$pi_dir/skills"
    cp -r "$repo_pi_dir/skills"/. "$1/$pi_dir/skills/"
  fi

  # AGENT.md
  if [ -f "$repo_pi_dir/AGENT.md" ]; then
    cp "$repo_pi_dir/AGENT.md" "$1/$pi_dir/AGENT.md"
  fi

  # settings (don't overwrite auth.json)
  if [ -f "$repo_pi_dir/settings.json" ]; then
    cp "$repo_pi_dir/settings.json" "$1/$pi_dir/settings.json"
  fi
}

install_claude () {
  if [ ! -d "$1/$claude_dir" ]; then
    mkdir -p "$1/$claude_dir"
  fi

  # agents
  if [ -d "$repo_claude_dir/agents" ]; then
    reset_dir "$1/$claude_dir/agents"
    cp -r "$repo_claude_dir/agents"/. "$1/$claude_dir/agents/"
  fi

  # commands
  if [ -d "$repo_claude_dir/commands" ]; then
    reset_dir "$1/$claude_dir/commands"
    cp -r "$repo_claude_dir/commands"/. "$1/$claude_dir/commands/"
  fi

  # references
  if [ -d "$repo_claude_dir/references" ]; then
    reset_dir "$1/$claude_dir/references"
    cp -r "$repo_claude_dir/references"/. "$1/$claude_dir/references/"
  fi

  # skills
  if [ -d "$repo_claude_dir/skills" ]; then
    reset_dir "$1/$claude_dir/skills"
    cp -r "$repo_claude_dir/skills"/. "$1/$claude_dir/skills/"
  fi

  # CLAUDE.md
  if [ -f "$repo_claude_dir/CLAUDE.md" ]; then
    cp "$repo_claude_dir/CLAUDE.md" "$1/$claude_dir/CLAUDE.md"
  fi
}

install_mempalace () {
  if [ ! -d "$1/.mempalace" ]; then
    mkdir -p "$1/.mempalace"
  fi

  # Config
  if [ -f "$repo_mempalace_dir/config.json" ]; then
    cp "$repo_mempalace_dir/config.json" "$1/.mempalace/config.json"
  fi

  # Converter script
  if [ -f "$repo_mempalace_dir/pi-to-transcript.py" ]; then
    cp "$repo_mempalace_dir/pi-to-transcript.py" "$1/.mempalace/pi-to-transcript.py"
  fi

  # Create runtime directories
  mkdir -p "$1/.mempalace/palace"
  mkdir -p "$1/.mempalace/pi-sessions"
}

install_dir="$HOME"
tmux_flag="false"
bash_flag="false"
vim_flag="false"
nvim_flag="false"
ghostty_flag="false"
aerospace_flag="false"
pi_flag="false"
claude_flag="false"
mempalace_flag="false"

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "Install configurations into directory"
      echo " "
      echo "./scripts/install.sh [options]"
      echo " "
      echo "options:"
      echo "-h, --help                show brief help"
      echo "--all                     install all configurations"
      echo "--bash                    install bash configurations"
      echo "--tmux                    install tmux configurations"
      echo "--vim                     install vim configurations"
      echo "--nvim                    install neovim configurations"
      echo "--ghostty                 install ghostty configurations"
      echo "--aerospace               install aerospace configurations"
      echo "--pi                      install pi coding agent configurations"
      echo "--claude                  install claude code configurations"
      echo "--mempalace               install mempalace configurations"
      echo "--install-dir=DIR         specify a directory to install to"
      echo "                          (typically your home directory)"
      exit 0
      ;;
    --all)
      tmux_flag="true"
      bash_flag="true"
      vim_flag="true"
      nvim_flag="true"
      ghostty_flag="true"
      aerospace_flag="true"
      pi_flag="true"
      claude_flag="true"
      mempalace_flag="true"
      shift
      ;;
    --bash)
      bash_flag="true"
      shift
      ;;
    --tmux)
      tmux_flag="true"
      shift
      ;;
    --vim)
      nvim_flag="true"
      shift
      ;;
    --nvim)
      nvim_flag="true"
      shift
      ;;
    --aerospace)
      aerospace_flag="true"
      shift
      ;;
    --pi)
      pi_flag="true"
      shift
      ;;
    --claude)
      claude_flag="true"
      shift
      ;;
    --mempalace)
      mempalace_flag="true"
      shift
      ;;
    --install-dir*)
      install_dir=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    *)
      break
      ;;
  esac
done

echo "Installing configurations in $install_dir"

# bash
if [ "$bash_flag" == "true" ]; then
  echo "Installing bash configurations..."
  install_bash "$install_dir"
fi

# tmux
if [ "$tmux_flag" == "true" ]; then
  echo "Installing tmux configurations..."
  install_tmux "$install_dir"
fi

# vim
#if [ "$vim_flag" == "true" ]; then
#  echo "Installing vim configurations..."
#  install_vim "$install_dir"
#fi

# neovim
if [ "$nvim_flag" == "true" ]; then
  echo "Installing neovim configurations..."
  install_nvim "$install_dir"
fi

# ghostty
if [ "$ghostty_flag" == "true" ]; then
  echo "Installing ghostty configurations..."
  install_ghostty "$install_dir"
fi

# aerospace
if [ "$aerospace_flag" == "true" ]; then
  echo "Installing aerospace configurations..."
  install_aerospace "$install_dir"
fi

# pi coding agent
if [ "$pi_flag" == "true" ]; then
  echo "Installing pi coding agent configurations..."
  install_pi "$install_dir"
fi

# claude code
if [ "$claude_flag" == "true" ]; then
  echo "Installing claude code configurations..."
  install_claude "$install_dir"
fi

# mempalace
if [ "$mempalace_flag" == "true" ]; then
  echo "Installing mempalace configurations..."
  install_mempalace "$install_dir"
fi
