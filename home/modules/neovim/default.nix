{
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
    gcc
    tree-sitter

    # For telescope fzf
    gnumake
  ];

  # TODO  home.activation to install nvim auto-magically
}
