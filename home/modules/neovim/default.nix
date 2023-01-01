{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    neovide
    luajitPackages.luarocks
  ];
}
