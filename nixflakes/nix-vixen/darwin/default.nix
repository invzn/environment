{ pkgs, ... }: {
  # here go the darwin preferences and config items
  #programs.zsh.enable = true;
  environment = {
    #shells = with pkgs; [ bash zsh ];
    #loginShell = pkgs.zsh;
    shells = with pkgs; [ bash ];
    loginShell = pkgs.bash;
    systemPackages = [ pkgs.coreutils ];
    #systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
  };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  fonts.fontDir.enable = true; # DANGER
  fonts.fonts = [ (pkgs.nerdfonts.override { fonts = [ "Droid Sans Mono" ]; }) ];
  services.nix-daemon.enable = true;
  system.defaults = {
    finder.AppleShowAllExtensions = true;
    finder._FXShowPosixPathInTitle = true;
    dock.autohide = true;
    NSGlobalDomain.AppleShowAllExtensions = true;
    NSGlobalDomain.InitialKeyRepeat = 14;
    NSGlobalDomain.KeyRepeat = 1;
  };
  # backwards compat; don't change
  system.stateVersion = 4;
  homebrew = {
    enable = false;
    #caskArgs.no_quarantine = true;
    #global.brewfile = true;
    #masApps = { };
    #casks = [];
    #taps = [];
    #brews = [];
  };
}
