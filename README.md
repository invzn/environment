environment
===========

My development environment.

# Setup

## NIX

For vixen machine:
```
nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch --flake ./nix-vixen
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
