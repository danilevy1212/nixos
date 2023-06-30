{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.go = {
    enable = true;
    goPath = ".cache/go";
  };
}
