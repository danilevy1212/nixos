{
  config,
  lib,
  pkgs,
  unstable,
  ...
}: let
  emacs-dir = "${config.xdg.configHome}/emacs";
  quivera = import ./quivera.nix {inherit pkgs;};
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
  home.packages = with pkgs;
    [
      # General Dependencies
      fd
      coreutils
      (lib.mkIf stdenv.isLinux clang)
      (ripgrep.override {withPCRE2 = true;})
      gnutls # for TLS connectivity
      zstd # for undo-fu-session/undo-tree compression
      pinentry-emacs # in-emacs gnupg prompts
    ]
    ++ (
      if stdenv.isLinux
      then [
        # Fonts
        emacs-all-the-icons-fonts
        ## Emacs
        sarasa-gothic
        dejavu_fonts
        symbola
        noto-fonts
        noto-fonts-emoji
        quivera
        ## Terminal
        victor-mono
      ]
      else []
    )
    ++ [
      # :editor
      # format
      nodePackages.prettier

      # :lang
      # go
      gopls
      gocode
      gore
      (lib.mkIf stdenv.isLinux golangci-lint)
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
    ]
    ++ (
      if stdenv.isLinux
      then [
        # latex
        texlive.combined.scheme-full
        texlab
      ]
      else []
    )
    ++ [
      # markdown
      pandoc

      # :term
      # eshell
      fish

      # :os
      (lib.mkIf stdenv.isLinux xclip)

      # :checkers
      languagetool
      (aspellWithDicts (d: with d; [es en en-computers en-science]))

      # :emacs
      # dired
      (lib.mkIf stdenv.isLinux imagemagick)

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
      rnix-lsp
    ]
    ++ (
      if stdenv.isLinux
      then [
        # :app
        # everywhere
        xclip
        xdotool
        xorg.xprop
        xorg.xwininfo
      ]
      else []
    )
    ++ [
      # telega
      ffmpeg-full
      libnotify
      tgs2png
      libwebp

      # detache
      dtach
    ];

  # I cannot live without you, my one true love...
  programs.emacs = with pkgs;
    lib.mkIf stdenv.isLinux {
      enable = true;
      package = emacsNativeComp;
      # For vterm.
      extraPackages = epkgs: with epkgs; [vterm oauth2];
    };

  # For :tools direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  services.lorri = lib.mkIf pkgs.stdenv.isLinux {enable = true;};

  # For :tools magit
  programs.git.delta = {
    enable = true;
    options = {syntax-theme = "Nord";};
  };

  # Doom directory.
  home.sessionVariables = {
    DOOMDIR = "$XDG_CONFIG_HOME/doom";
    LSP_USE_PLIST = "1";
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
