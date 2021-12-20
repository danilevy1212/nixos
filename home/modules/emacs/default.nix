{ config, lib, pkgs, ... }:
let
  quivira = with pkgs;
    stdenv.mkDerivation {
      pname = "Quivera";
      version = "0.0.1";
      src = fetchurl {
        url = "http://www.quivira-font.com/files/Quivira.ttf";
        sha256 = "0z2vh58g9x7gji31mwg1gz5gs1r9rf4s9wyiw92dc7xyvibai6dv";
      };
      sourceRoot = "./";
      unpackCmd = ''
        ttfName=$(basename $(stripHash $curSrc))
        cp $curSrc ./$ttfName
      '';
      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        cp -a *.ttf $out/share/fonts/truetype/
      '';
    };
in {
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

    ## Emacs
    sarasa-gothic
    dejavu_fonts
    symbola
    noto-fonts
    noto-fonts-emoji
    quivira

    ## Terminal
    victor-mono

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
    tdlib
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
    package = pkgs.emacsGcc;
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
    TDLIB_PREFIX = "${pkgs.tdlib.outPath}";
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
