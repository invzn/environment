#!/bin/sh

repo_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
repo_dotfiles_dir="$repo_dir/dotfiles"
repo_bash_dir="$repo_dotfiles_dir/bash"
repo_vim_dir="$repo_dotfiles_dir/vim"
repo_nvim_dir="$repo_dotfiles_dir/config/nvim"
repo_ghostty_dir="$repo_dotfiles_dir/config/ghostty"
repo_aerospace_dir="$repo_dotfiles_dir/config/aerospace"

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
    cp $1/.bash_profile $repo_dotfiles_dir/bashrc
  elif [ -f "$1/.bashrc" ]; then
    cp $1/.bashrc $repo_dotfiles_dir/bashrc
  fi
  if [ -d "$1/$bash_dir" ] && \
    [ -n "$(ls -A $1/$bash_dir 2>/dev/null)" ]; then
    cp -r $1/$bash_dir/* $repo_bash_dir/.
  fi
}

# tmux configs
update_tmux () {
  if [ -f "$1/.tmux.conf" ]; then
    cp $1/.tmux.conf $repo_dotfiles_dir/tmux.conf
  fi
}

# vim configs
update_vim () {
  if [ -f "$1/.vimrc" ]; then
    cp $1/.vimrc $repo_dotfiles_dir/vimrc
  fi
  if [ -d "$1/$vim_dir" ] && \
    [ -n "$(ls -A $1/$vim_dir 2>/dev/null)" ]; then
    cp $1/$vim_dir/Vimfile $repo_vim_dir/.
    if [ -d "$1/$vim_dir/colors" ] && \
      [ -n "$(ls -A $1/$vim_dir/colors 2>/dev/null)" ]; then
      cp -r $1/$vim_dir/colors/* $repo_vim_dir/colors/.
    fi
    if [ -d "$1/$vim_dir/config" ] && \
      [ -n "$(ls -A $1/$vim_dir/config 2>/dev/null)" ]; then
      cp -r $1/$vim_dir/config/* $repo_vim_dir/config/.
    fi
  fi 
}

# neovim
update_nvim () {
  if [ -d "$1/$nvim_dir" ] && \
    [ -n "$(ls -A $1/$nvim_dir 2>/dev/null)" ]; then
    cp -r $1/$nvim_dir/* $repo_nvim_dir/.
  fi
}

# ghostty
update_ghostty () {
  if [ -d "$1/$ghostty_dir" ] && [ -n "$(ls -A $1/$ghostty_dir 2>/dev/null)" ]; then
    cp -r $1/$ghostty_dir/* $repo_ghostty_dir/.
  fi
}

# aerospace
update_aerospace () {
  if [ "$(uname -s)" == "Darwin" ] && \
    [ -d "$1/$aerospace_dir" ] && \
    [ -n "$(ls -A $1/$aerospace_dir 2>/dev/null)" ]; then
    cp -r $1/$aerospace_dir/* $repo_aerospace_dir/.
  fi
}

install_dir="$HOME"
tmux_flag="false"
bash_flag="false"
vim_flag="false"
nvim_flag="false"
ghostty_flag="false"
aerospace_flag="false"

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
  update_bash $install_dir
fi

# tmux
if [ "$tmux_flag" == "true" ]; then
  echo "Copying tmux configurations..."
  update_tmux $install_dir
fi

# vim
#if [ "$vim_flag" == "true" ]; then
#  echo "Copying vim configurations..."
#  update_vim $install_dir
#fi

# neovim
if [ "$nvim_flag" == "true" ]; then
  echo "Copying neovim configurations..."
  update_nvim $install_dir
fi

# ghostty
if [ "$ghostty_flag" == "true" ]; then
  echo "Copying ghostty configurations..."
  update_ghostty $install_dir
fi

# aerospace
if [ "$aerospace_flag" == "true" ]; then
  echo "Copying aerospace configurations..."
  update_aerospace $install_dir
fi
