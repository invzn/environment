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

reset_dir () {
  if [ ! -d "$1" ]; then
    mkdir $1
  elif [ -n "$(ls -A $1 2>/dev/null)" ]; then
    rm -rf $1/*
  fi
}

setup_xdg_config () {
  if [ ! -d "$1/$xdg_config_dir" ]; then
    mkdir $1/$xdg_config_dir 
  fi
}

install_bash () {
  if [ "$(uname -s)" == "Darwin" ]; then
    cp $repo_dotfiles_dir/bashrc $1/.bash_profile
  else
    cp $repo_dotfiles_dir/bashrc $1/.bashrc
  fi
  reset_dir "$1/$bash_dir"
  cp -r $repo_bash_dir/* $1/$bash_dir/.
}

install_tmux () {
  cp $repo_dotfiles_dir/tmux.conf $1/.tmux.conf
}

install_vim () {
  cp $repo_dotfiles_dir/vimrc ~/.vimrc
  reset_dir "$1/$vim_dir"
  cp -r $repo_vim_dir/* $1/$vim_dir/.
}

install_nvim () {
  setup_xdg_config $1

  reset_dir "$1/$nvim_dir"
  cp -r $repo_nvim_dir/* $1/$nvim_dir/.
}

install_ghostty () {
  setup_xdg_config $1

  reset_dir "$1/$ghostty_dir"
  cp -r $repo_ghostty_dir/* $1/$ghostty_dir/.
}

install_aerospace () {
  if [ "$(uname -s)" == "Darwin" ]; then
    setup_xdg_config $1

    reset_dir "$1/$aerospace_dir"
    cp -r $repo_aerospace_dir/* $1/$aerospace_dir/.
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

echo "Installing configurations in $install_dir"

# bash
if [ "$bash_flag" == "true" ]; then
  echo "Installing bash configurations..."
  install_bash $install_dir
fi

# tmux
if [ "$tmux_flag" == "true" ]; then
  echo "Installing tmux configurations..."
  install_tmux $install_dir
fi

# vim
#if [ "$vim_flag" == "true" ]; then
#  echo "Installing vim configurations..."
#  install_vim $install_dir
#fi

# neovim
if [ "$nvim_flag" == "true" ]; then
  echo "Installing neovim configurations..."
  install_nvim $install_dir
fi

# ghostty
if [ "$ghostty_flag" == "true" ]; then
  echo "Installing ghostty configurations..."
  install_ghostty $install_dir
fi

# aerospace
if [ "$aerospace_flag" == "true" ]; then
  echo "Installing aerospace configurations..."
  install_aerospace $install_dir
fi
