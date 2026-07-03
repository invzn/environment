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

xdg_config_dir=".config"
bash_dir=".bash"
vim_dir=".vim"
nvim_dir="$xdg_config_dir/nvim"
ghostty_dir="$xdg_config_dir/ghostty"
aerospace_dir="$xdg_config_dir/aerospace"

# bash
update_bash () {
  if [ "$(uname -s)" == "Darwin" ] && \
    [ -f "$1/.bash_profile" ]; then
    cp "$1/.bash_profile" "$repo_dotfiles_dir/bashrc"
  elif [ -f "$1/.bashrc" ]; then
    cp "$1/.bashrc" "$repo_dotfiles_dir/bashrc"
  fi
  if [ -d "$1/$bash_dir" ] && \
    [ -n "$(ls -A "$1/$bash_dir" 2>/dev/null)" ]; then
    cp -r "$1/$bash_dir"/. "$repo_bash_dir/"
  fi
}

# tmux configs
update_tmux () {
  if [ -f "$1/.tmux.conf" ]; then
    cp "$1/.tmux.conf" "$repo_dotfiles_dir/tmux.conf"
  fi
}

# vim configs
update_vim () {
  if [ -f "$1/.vimrc" ]; then
    cp "$1/.vimrc" "$repo_dotfiles_dir/vimrc"
  fi
  if [ -d "$1/$vim_dir" ] && \
    [ -n "$(ls -A "$1/$vim_dir" 2>/dev/null)" ]; then
    cp "$1/$vim_dir/Vimfile" "$repo_vim_dir/"
    if [ -d "$1/$vim_dir/colors" ] && \
      [ -n "$(ls -A "$1/$vim_dir/colors" 2>/dev/null)" ]; then
      cp -r "$1/$vim_dir/colors"/. "$repo_vim_dir/colors/"
    fi
    if [ -d "$1/$vim_dir/config" ] && \
      [ -n "$(ls -A "$1/$vim_dir/config" 2>/dev/null)" ]; then
      cp -r "$1/$vim_dir/config"/. "$repo_vim_dir/config/"
    fi
  fi 
}

# neovim
update_nvim () {
  if [ -d "$1/$nvim_dir" ] && \
    [ -n "$(ls -A "$1/$nvim_dir" 2>/dev/null)" ]; then
    cp -r "$1/$nvim_dir"/. "$repo_nvim_dir/"
  fi
}

# ghostty
update_ghostty () {
  if [ -d "$1/$ghostty_dir" ] && [ -n "$(ls -A "$1/$ghostty_dir" 2>/dev/null)" ]; then
    cp -r "$1/$ghostty_dir"/. "$repo_ghostty_dir/"
  fi
}

# aerospace
update_aerospace () {
  if [ "$(uname -s)" == "Darwin" ] && \
    [ -d "$1/$aerospace_dir" ] && \
    [ -n "$(ls -A "$1/$aerospace_dir" 2>/dev/null)" ]; then
    cp -r "$1/$aerospace_dir"/. "$repo_aerospace_dir/"
  fi
}

pi_dir=".pi/agent"
claude_dir=".claude"

# pi coding agent
update_pi () {
  if [ -d "$1/$pi_dir" ]; then
    # agents
    if [ -d "$1/$pi_dir/agents" ] && \
      [ -n "$(ls -A "$1/$pi_dir/agents" 2>/dev/null)" ]; then
      mkdir -p "$repo_pi_dir/agents"
      # Resolve symlinks with cp -L
      for f in "$1/$pi_dir/agents"/*.md; do
        [ -f "$f" ] && cp -L "$f" "$repo_pi_dir/agents/"
      done
    fi

    # extensions
    if [ -d "$1/$pi_dir/extensions" ] && \
      [ -n "$(ls -A "$1/$pi_dir/extensions" 2>/dev/null)" ]; then
      mkdir -p "$repo_pi_dir/extensions"
      cp -rL "$1/$pi_dir/extensions"/. "$repo_pi_dir/extensions/"
    fi

    # prompts
    if [ -d "$1/$pi_dir/prompts" ] && \
      [ -n "$(ls -A "$1/$pi_dir/prompts" 2>/dev/null)" ]; then
      mkdir -p "$repo_pi_dir/prompts"
      for f in "$1/$pi_dir/prompts"/*.md; do
        [ -f "$f" ] && cp -L "$f" "$repo_pi_dir/prompts/"
      done
    fi

    # references
    if [ -d "$1/$pi_dir/references" ] && \
      [ -n "$(ls -A "$1/$pi_dir/references" 2>/dev/null)" ]; then
      mkdir -p "$repo_pi_dir/references"
      for f in "$1/$pi_dir/references"/*.md; do
        [ -f "$f" ] && cp -L "$f" "$repo_pi_dir/references/"
      done
    fi

    # skills
    if [ -d "$1/$pi_dir/skills" ] && \
      [ -n "$(ls -A "$1/$pi_dir/skills" 2>/dev/null)" ]; then
      mkdir -p "$repo_pi_dir/skills"
      cp -rL "$1/$pi_dir/skills"/. "$repo_pi_dir/skills/"
    fi

    # AGENT.md
    if [ -f "$1/$pi_dir/AGENT.md" ]; then
      cp -L "$1/$pi_dir/AGENT.md" "$repo_pi_dir/AGENT.md"
    fi

    # settings (never copy auth.json or sessions)
    if [ -f "$1/$pi_dir/settings.json" ]; then
      cp "$1/$pi_dir/settings.json" "$repo_pi_dir/settings.json"
    fi
  fi
}

# claude code
update_claude () {
  if [ -d "$1/$claude_dir" ]; then
    # agents
    if [ -d "$1/$claude_dir/agents" ] && \
      [ -n "$(ls -A "$1/$claude_dir/agents" 2>/dev/null)" ]; then
      mkdir -p "$repo_claude_dir/agents"
      for f in "$1/$claude_dir/agents"/*.md; do
        [ -f "$f" ] && cp -L "$f" "$repo_claude_dir/agents/"
      done
    fi

    # commands
    if [ -d "$1/$claude_dir/commands" ] && \
      [ -n "$(ls -A "$1/$claude_dir/commands" 2>/dev/null)" ]; then
      mkdir -p "$repo_claude_dir/commands"
      for f in "$1/$claude_dir/commands"/*.md; do
        [ -f "$f" ] && cp -L "$f" "$repo_claude_dir/commands/"
      done
    fi

    # references
    if [ -d "$1/$claude_dir/references" ] && \
      [ -n "$(ls -A "$1/$claude_dir/references" 2>/dev/null)" ]; then
      mkdir -p "$repo_claude_dir/references"
      for f in "$1/$claude_dir/references"/*.md; do
        [ -f "$f" ] && cp -L "$f" "$repo_claude_dir/references/"
      done
    fi

    # skills (nested: skills/<skill-name>/SKILL.md)
    if [ -d "$1/$claude_dir/skills" ] && \
      [ -n "$(ls -A "$1/$claude_dir/skills" 2>/dev/null)" ]; then
      mkdir -p "$repo_claude_dir/skills"
      cp -rL "$1/$claude_dir/skills"/. "$repo_claude_dir/skills/"
    fi

    # CLAUDE.md
    if [ -f "$1/$claude_dir/CLAUDE.md" ]; then
      cp -L "$1/$claude_dir/CLAUDE.md" "$repo_claude_dir/CLAUDE.md"
    fi

    # Never copy back: settings.json, projects/, sessions/, cache/,
    # plugins/, history.jsonl, telemetry/, todos/, downloads/, etc.
  fi
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

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "Update repo with installed configurations"
      echo " "
      echo "./scripts/update_repo.sh [options]"
      echo " "
      echo "options:"
      echo "-h, --help                show brief help"
      echo "--all                     update all configurations"
      echo "--bash                    update bash configurations"
      echo "--tmux                    update tmux configurations"
      echo "--vim                     update vim configurations"
      echo "--nvim                    update neovim configurations"
      echo "--ghostty                 update ghostty configurations"
      echo "--aerospace               update aerospace configurations"
      echo "--pi                      update pi coding agent configurations"
      echo "--claude                  update claude code configurations"
      echo "--install-dir=DIR         specify a directory to pull configurations from"
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
    --install-dir*)
      install_dir=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    *)
      break
      ;;
  esac
done

echo "Copying configurations in $install_dir into repo..."

# bash
if [ "$bash_flag" == "true" ]; then
  echo "Copying bash configurations..."
  update_bash "$install_dir"
fi

# tmux
if [ "$tmux_flag" == "true" ]; then
  echo "Copying tmux configurations..."
  update_tmux "$install_dir"
fi

# vim
#if [ "$vim_flag" == "true" ]; then
#  echo "Copying vim configurations..."
#  update_vim "$install_dir"
#fi

# neovim
if [ "$nvim_flag" == "true" ]; then
  echo "Copying neovim configurations..."
  update_nvim "$install_dir"
fi

# ghostty
if [ "$ghostty_flag" == "true" ]; then
  echo "Copying ghostty configurations..."
  update_ghostty "$install_dir"
fi

# aerospace
if [ "$aerospace_flag" == "true" ]; then
  echo "Copying aerospace configurations..."
  update_aerospace "$install_dir"
fi

# pi coding agent
if [ "$pi_flag" == "true" ]; then
  echo "Copying pi coding agent configurations..."
  update_pi "$install_dir"
fi

# claude code
if [ "$claude_flag" == "true" ]; then
  echo "Copying claude code configurations..."
  update_claude "$install_dir"
fi

