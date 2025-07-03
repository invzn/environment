# Configure vixen with nix, home-manager

---

## Install nix:

To install nix run the following command provided by [DeterminateSystems](https://github.com/DeterminateSystems/nix-installer):

```
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

Important: Make sure you say no when the installer asks you to install **Determinate Nix**:

```
Install Determinate Nix?

Determinate Nix is tested and ready for macOS Tahoe when you are.  It is built for people and teams, with dozens of user experience, performance, and reliability improvements. Selecting ‘no’ will install Nix from NixOS.

Proceed? ([Y]es/[n]o/[e]xplain): n
```

## Install nix home-manager plugin:

```
nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

## Configure vixen:
```
home-manager switch --flake ./nixflakes/nix-vixen
```

---

## Uninstall home-manager:

```
nix run home-manager -- uninstall
```

## Uninstall nix:

```
/nix/nix-installer uninstall
```
