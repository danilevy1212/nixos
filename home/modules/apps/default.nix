{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    # video player
    mpv-with-scripts
  ];

  # default browser
  home.sessionVariables = {BROWSER = "brave";};

  imports = [
    ./linux-apps.nix
  ];
}
