{
  config,
  lib,
  pkgs,
  ...
}: {
  # Video Player
  programs.mpv = {
    enable = true;
    config = {
      sub-auto = "all";
    };
  };

  # default browser
  home.sessionVariables = {BROWSER = "brave";};

  imports = [
    ./linux-apps.nix
  ];
}
