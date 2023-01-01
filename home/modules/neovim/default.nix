{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    neovide
    luajitPackages.luarocks

    # For lua
    stylua
    sumneko-lua-language-server

    # For nix
    alejandra
  ];
}
