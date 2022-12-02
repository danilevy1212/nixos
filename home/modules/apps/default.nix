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
      sub-auto = "exact";
      save-position-on-quit = true;
    };
  };

  # default browser
  home.sessionVariables = {BROWSER = "brave";};

  imports = [
    ./linux-apps.nix
  ];
}
