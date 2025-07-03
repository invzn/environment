# Configure osx machine with nix, home-manager

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

## Install nix nix-darwin plugin:

### Create flake.nix

```
sudo mkdir -p /etc/nix-darwin
sudo chown $(id -nu):$(id -ng) /etc/nix-darwin
cd /etc/nix-darwin

# To use Nixpkgs unstable:
nix flake init -t nix-darwin/master
# To use Nixpkgs 25.05:
nix flake init -t nix-darwin/nix-darwin-25.05

sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix
```

### Installing nix-darwin

```
sudo nix run nix-darwin/master#darwin-rebuild -- switch
```

### Using nix-darwin

```
sudo darwin-rebuild switch
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
