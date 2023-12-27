{
  config,
  lib,
  pkgs,
  ...
}: let
  goPath = ".cache/go";
in {
  programs.go = {
    enable = true;
    inherit goPath;
  };

  # Add goPath bin to path.
  home.sessionPath = ["$HOME/${goPath}/bin"];
}
