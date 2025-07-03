{ config, pkgs, ... }: 

let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  home.username = "crosario";
  home.homeDirectory = "/Users/crosario";

  home.packages = with pkgs; [
    ripgrep
    fd
    curl
    less
    sqlite
  ];

  xdg.enable = true;
  xdg.configFile.nvim.source = mkOutOfStoreSymlink "/Users/crosario/.config/nvim";

  programs.fzf.enable = true;
  programs.git.enable = true;

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
      #{
      #  plugin = pkgs.vimPlugins.telescope-nvim;
      #  config = ''
      #    require('telescope').setup {
      #      defaults = {
      #        mappings = {
      #          i = {
      #            ["<C-j>"] = "cycle_history_next",
      #            ["<C-k>"] = "cycle_history_prev",
      #            ["<C-w>"] = "send_to_qf",
      #          },
      #        },
      #        -- Other Telescope configurations
      #      }
      #    }
      #  '';
      #}
    ];
    # Use the Nix package search engine to find
    # even more plugins : https://search.nixos.org/packages

    extraConfig = ''
      require('config.options')
      require('config.lazy')
      require('config.telescope')
      require('config.kanagawa')
      require('config.lualine')
      require('config.lsp')
    '';
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Don't change this when you change package input. Leave it alone.
  home.stateVersion = "25.11";
}
