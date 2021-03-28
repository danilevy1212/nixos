{ config, lib, pkgs, ... }:
{
  programs.go.enable = true;

  home.sessionVariables = { GOPATH = "$XDG_DATA_HOME/go"; };
}
