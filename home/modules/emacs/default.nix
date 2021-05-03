{ config, lib, pkgs, ... }: {
  # Doom emacs dependencies
  home.packages = with pkgs; [
    # General Dependencies
    fd
    (ripgrep.override { withPCRE2 = true; })
    gnutls # for TLS connectivity
    zstd # for undo-fu-session/undo-tree compression
    pinentry_emacs # in-emacs gnupg prompts

    # Fonts
    emacs-all-the-icons-fonts
    hack-font
    dejavu_fonts
    symbola
    noto-fonts
    noto-fonts-cjk # FIXME alternative https://github.com/hakatashi/RictyDiminished-with-FiraCode
    noto-fonts-emoji
    victor-mono # For terminal?

    # For emacs
    fira-mono
    fira-code
    fira-code-symbols
    # FIXME MISSING Quivera
    # :editor
    # format
    nodePackages.prettier

    # :lang
    # nix
    nixfmt

    # sh
    shellcheck

    # json
    jq

    # :term
    # eshell
    fish

    # :os
    xclip

    # :checkers
    languagetool
    (aspellWithDicts (d: with d; [ es en en-computers en-science ]))

    # :emacs
    # dired
    imagemagick

    # :tools
    # lookup
    sqlite
    wordnet

    # editorconfig
    editorconfig-core-c

    # lsp
    unzip
    python3

    # :app
    # everywhere
    xclip
    xdotool
    xorg.xprop
    xorg.xwininfo
  ];

  # I cannot live without you, my one true love...
  programs.emacs = {
    enable = true;
    package = pkgs.emacsPgtkGcc;
    # For vterm.
    extraPackages = epkgs: [
      epkgs.vterm
      # spotify
      epkgs.oauth2
      # pdf-tools
      epkgs.pdf-tools
      epkgs.org-pdftools
    ];
  };

  # For :tools direnv
  programs.direnv = {
    enable = true;
    enableNixDirenvIntegration = true;
  };

  home.sessionVariables = { DOOMDIR = "$XDG_CONFIG_HOME/doom"; };
}
