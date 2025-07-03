environment
===========

My development environment.

# Setup

## Dotfiles

---

To install on a new system:

```
./scripts/install.sh
```

To update a system:

```
./scripts/update.sh
```

To update the repo with current dotfiles:

```
./scripts/update_repo.sh
```

# Repo Structure

---

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
