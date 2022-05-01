{
  config,
  lib,
  pkgs,
  unstable,
  ...
}: let
  emacs-dir = "${config.xdg.configHome}/emacs";
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
  tgs2png = with pkgs;
    stdenv.mkDerivation rec {
      pname = "tgs2png";
      version = "0.0.1";
      src = fetchgit {
        name = pname;
        url = "https://github.com/zevlg/tgs2png";
        rev = "69e3605d7f78d80b1225f9043e420b68c214dfe1";
        sha256 = "sha256-ET/GO+pVq6FcRKr1Nds3UUe1AosSJ+m8ngJ+0erTfxE=";
      };
      buildInputs = [rlottie libpng cmake pkg-config];
      configurePhase = ''
        cmake .
      '';
      buildPhase = ''
        make
      '';
      installPhase = ''
        mkdir -p $out/bin
        mv tgs2png $out/bin
      '';
    };
in {
  # Doom emacs dependencies
  home.packages = with pkgs; [
    # General Dependencies
    fd
    coreutils
    clang
    (ripgrep.override {withPCRE2 = true;})
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
    # go
    gopls
    gocode
    gore
    golangci-lint
    gotools
    gotests
    gomodifytags

    # nix
    alejandra
    nixfmt

    # sh
    shellcheck
    shfmt

    # json
    jq

    # lua
    sumneko-lua-language-server

    # python
    pyright
    black
    python39Packages.nose
    python39Packages.pyflakes
    python39Packages.isort
    python39Packages.ipython

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
    (aspellWithDicts (d: with d; [es en en-computers en-science]))

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
    ffmpeg-full
    libnotify
    tgs2png
    libwebp

    # dtache
    dtach
  ];

  # I cannot live without you, my one true love...
  programs.emacs = {
    enable = true;
    package = pkgs.emacsPgtkGcc;
    # For vterm.
    extraPackages = epkgs: [epkgs.vterm epkgs.oauth2];
  };

  # For :tools direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = builtins.readFile ./readlib.sh;
  };
  services.lorri.enable = true;

  # For :tools magit
  programs.git.delta = {
    enable = true;
    options = {syntax-theme = "Nord";};
  };

  # Doom directory.
  home.sessionVariables = {
    DOOMDIR = "$XDG_CONFIG_HOME/doom";
  };

  # Add bin/doom to path.
  home.sessionPath = ["${emacs-dir}/bin"];

  # "auto" install doom-emacs
  home.activation = {
    doom-install = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d ${emacs-dir} ]
      then
         $DRY_RUN_CMD git clone https://github.com/hlissner/doom-emacs ${emacs-dir}
      fi
    '';
  };

  programs.zsh.shellAliases = {
    # kill emacsclient kill server alias
    ek = "emacsclient -e '(kill-emacs)'";
    # create a terminal emacs
    emt = "emacsclient -nw";
  };
}
