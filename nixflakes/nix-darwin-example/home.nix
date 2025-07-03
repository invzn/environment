# home.nix
# home-manager switch 

{ config, pkgs, ... }:

{
  home.username = "crosario";
  home.homeDirectory = "/Users/crosario";
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # Makes sense for user specific applications that shouldn't be available system-wide
  home.packages = [
    pkgs.bash
    pkgs.git
    pkgs.tmux
    pkgs.zoxide
    pkgs.sesh
    pkgs.neovim
    pkgs.vim
    pkgs.tree
    pkgs.fzf
    pkgs.ack
    pkgs.gnused
    pkgs.sqlite
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # ".zshrc".source = ~/dotfiles/zshrc/.zshrc;
    # ".config/wezterm".source = ~/dotfiles/wezterm;
    # ".config/skhd".source = ~/dotfiles/skhd;
    # ".config/starship".source = ~/dotfiles/starship;
    # ".config/zellij".source = ~/dotfiles/zellij;
    # ".config/nvim".source = ~/dotfiles/nvim;
    # ".config/nix".source = ~/dotfiles/nix;
    # ".config/nix-darwin".source = ~/dotfiles/nix-darwin;
    # ".config/tmux".source = ~/dotfiles/tmux;
    # ".config/ghostty".source = ~/dotfiles/ghostty;
    # ".config/aerospace".source = ~/dotfiles/aerospace;
    # ".config/sketchybar".source = ~/dotfiles/sketchybar;
    # ".config/nushell".source = ~/dotfiles/nushell;
  };

  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
  programs.bash.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = false;
    vimAlias = false;
    vimdiffAlias = false;
    plugins = with pkgs.vimPlugins; [
      {
        plugin = sqlite-lua;
        config = "let g:sqlite_clib_path = '${pkgs.sqlite.out}/lib/libsqlite3${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}'";
      }
    ];
    # Use the Nix package search engine to find
    # even more plugins : https://search.nixos.org/packages
  };
}
