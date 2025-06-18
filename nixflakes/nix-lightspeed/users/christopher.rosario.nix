{ config, pkgs, ... }:

{
  description = "lightspeed laptop user: christopher.rosario";
  name = "christopher.rosario";
  shell = pkgs.bashInteractive;
  # These packages will only be installed for your user
  # The binaries will be available in the following path: /etc/profiles/per-user/$USER/bin
  packages = [
    pkgs.bash
    pkgs.git
    pkgs.tmux
    pkgs.zoxide
    pkgs.sesh
    pkgs.vim
    pkgs.tree
    pkgs.fzf
    pkgs.ack
    pkgs.gnused
  ];
}
