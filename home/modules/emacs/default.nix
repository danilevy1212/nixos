{ config, lib, pkgs, ... }: {
  # TODO Inspiration https://github.com/hlissner/dotfiles/blob/master/modules/editors/emacs.nix, from the horses mouth.
  # TODO EmacsPgtGcc, try out with cachix+nix-community

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
    noto-fonts-cjk
    noto-fonts-emoji
    # FIXME MISSING Quivera

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

  # TODO
  # For spotify
  # services.spotifyd = {
  #   enable = true;
  #   settings = {
  #     # Options at https://spotifyd.github.io/spotifyd/config/File.html
  #     global = { user, password, device... };
  #   };
  # };

  # I cannot live without you, my one true love...
  programs.emacs = {
    enable = true;
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
