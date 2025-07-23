environment
===========

My development environment.

# Install

To install all configurations:

```
./script/install.sh --all
```

To install a specific configuration(s):

```
./script/install.sh --bash      # install bash configurations
./script/install.sh --tmux      # install tmux configurations
./script/install.sh --vim       # install vim configurations
./script/install.sh --nvim      # install neovim configurations
./script/install.sh --ghostty   # install ghostty configurations
./script/install.sh --aerospace # install aerospace configurations
```

# Update Repo with Local Configuration

To update repo with all local configurations:

```
./script/install.sh --all
```

To update repo with a specific local configuration(s):

```
./script/update_repo.sh --bash      # update repo with local bash configurations
./script/update_repo.sh --tmux      # update repo with local tmux configurations
./script/update_repo.sh --vim       # update repo with local vim configurations
./script/update_repo.sh --nvim      # update repo with local neovim configurations
./script/update_repo.sh --ghostty   # update repo with local ghostty configurations
./script/update_repo.sh --aerospace # update repo with local aerospace configurations
```

# Structure

```
github.com/invzn/environment
├── README.md
├── brew_list.txt  // homebrew list of installed packages
├── dotfiles       // dotfiles
├── iterm2         // iterm2 config
├── nixflakes      // nix flakes
└── scripts
    ├── install.sh      // install dotfiles
    ├── update.sh       // update dotfiles
    └── update_repo.sh  // update repo dotfiles from local machine
```
