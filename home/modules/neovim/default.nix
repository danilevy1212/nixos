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

    # For tree-sitter
    zig
    clang
    tree-sitter

    # For telescope fzf
    (lib.mkIf pkgs.stdenv.isLinux gnumake)
  ];
}
