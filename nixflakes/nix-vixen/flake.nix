{
  description = "vixen flake";
  inputs = {
    # Where we get most of our software. Giant mono repo with recipes
    # called derivations that say how to build software.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; # 25.11

    # Manages configs links things into your home directory
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Controls system level software and settings including fonts
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    ## Tricked out nvim
    #pwnvim.url = "github:zmre/pwnvim";
  };
  outputs = inputs@{ nixpkgs, home-manager, darwin, ... }: {
    darwinConfigurations.vixen = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import nixpkgs { system = "aarch64-darwin"; };
      modules = [ ./darwin ];
    };
    homeConfigurations = {
      "crosario" = home-manager.lib.homeManagerConfiguration {
        # System is very important!
        pkgs = import nixpkgs { system = "aarch64-darwin"; };

        modules = [ ./home-manager ]; # Defined later
      };
    };
  };
}
