{
  description = "neovim flake";

  inputs = {
    nixpkgs.follows = "nixvim/nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
  };

  outputs =
    { nixpkgs, nixvim, ... }:
    let
      config = {
        colorschemes.gruvbox.enable = true;
      };

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          nixvim' = nixvim.legacyPackages.${system};
          nvim = nixvim'.makeNixvim config;
        in
        {
          inherit nvim;
          default = nvim;
        }
      );
    };
}
