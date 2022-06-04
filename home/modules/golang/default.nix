{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.go = {
    enable = true;
    goPath = "$XDG_CACHE_HOME/go";
  };
}
