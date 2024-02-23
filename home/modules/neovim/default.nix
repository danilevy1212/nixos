{pkgs, ...}: {
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

  # Basic settings for neovim + terminal integration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimdiffAlias = true;
    vimAlias = true;
    # For CopilotChat
    extraPython3Packages = ps:
      with ps; [
        pynvim
        prompt-toolkit
        tiktoken
        python-dotenv
        requests
      ];
  };

  # TODO  home.activation to install nvim auto-magically
}
