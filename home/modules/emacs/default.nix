# TODO Remove when I start using `flakes`
let
  nixpkgs = import <nixpkgs> { };
  tdlib_latest = (nixpkgs.tdlib.overrideAttrs (old: {
    version = "1.7.9";

    src = nixpkgs.fetchFromGitHub {
      owner = "tdlib";
      repo = "td";
      # https://github.com/tdlib/td/issues/1718
      rev = "7d41d9eaa58a6e0927806283252dc9e74eda5512";
      sha256 = "09b7srbfqi4gmg5pdi398pr0pxihw4d3cw85ycky54g862idzqs8";
    };
  }));
in { config, lib, pkgs, ... }: {
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
    sarasa-gothic
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

    # lua
    sumneko-lua-language-server

    # python
    pyright
    black
    # python38Packages.nose
    python38Packages.pyflakes
    python38Packages.isort

    # latex
    texlive.combined.scheme-full
    texlab

    # markdown
    pandoc

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
    zip
    python3
    pipenv
    poetry

    # :app
    # everywhere
    xclip
    xdotool
    xorg.xprop
    xorg.xwininfo

    # telega
    tdlib_latest
    gnumake
    gperf
    cmake
    ffmpeg
    libappindicator
    clang
  ];

  # I cannot live without you, my one true love...
  programs.emacs = {
    enable = true;
    package = pkgs.emacsPgtkGcc;
    # For vterm.
    extraPackages = epkgs: [ epkgs.vterm epkgs.oauth2 ];
  };

  # For :tools direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # For :tools magit
  programs.git.delta = {
    enable = true;
    options = { syntax-theme = "Nord"; };
  };

  # Doom directory.
  home.sessionVariables = {
    DOOMDIR = "$XDG_CONFIG_HOME/doom";
    TDLIB_PREFIX = "${tdlib_latest.outPath}";
  };

  # Add bin/doom to path.
  home.sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];

  programs.zsh.shellAliases = {
    # kill emacsclient kill server alias
    ek = "emacsclient -e '(kill-emacs)'";
    # create a terminal emacs
    emt = "emacsclient -nw";
  };
}
