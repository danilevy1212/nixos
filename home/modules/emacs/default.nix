{
  config,
  lib,
  pkgs,
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
  config = {
    # Doom emacs dependencies
    home.packages = with pkgs;
      [
        # General Dependencies
        fd
        coreutils
        (ripgrep.override {withPCRE2 = true;})
        gnutls # for TLS connectivity
        zstd # for undo-fu-session/undo-tree compression
        pinentry-emacs # in-emacs gnupg prompts
      ]
      ++ [
        # Fonts
        emacs-all-the-icons-fonts
        ## Emacs
        # TODO  Keep Sarasa UI for GUI, use Ioveska Nerd Font for TUI with sarasa-gothic as backup
        sarasa-gothic
        dejavu_fonts
        symbola
        noto-fonts
        noto-fonts-emoji
        quivera
        ## Terminal
        # TODO Replace with Ioveska Nerd Font
        victor-mono
      ]
      ++ [
        # :editor
        # format
        nodePackages.prettier

        # nix
        alejandra

        # sh
        shellcheck
        shfmt

        # json
        jq
      ]
      ++
      # FIXME  Move this to a shell nix file
      # ++ (
      #   # Only in my personal computer
      #   if hostname == HOSTS.nyx15v2
      #   then [
      #     # latex
      #     texlive.combined.scheme-full
      #     texlab
      #   ]
      #   else []
      # )
      /*
      ++
      */
      [
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
      ]
      ++ [
        # :app
        # everywhere
        xclip
        xdotool
        xorg.xprop
        xorg.xwininfo
      ]
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
    programs.emacs = with pkgs; {
      enable = true;
      package = emacs29-pgtk;
      # For vterm.
      extraPackages = epkgs: with epkgs; [vterm oauth2];
    };

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
      # NOTE  If I change the url to `ssh`, this will run as my home.user, so you will need to manually setup the ssh key with github.
      #       I should probably make it an option somewhere to either use ssh or https.
      doom-install = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ ! -d ${emacs-dir} ]
        then
           $DRY_RUN_CMD ${pkgs.gitAndTools.gitFull}/bin/git clone https://github.com/hlissner/doom-emacs ${emacs-dir}
        fi
      '';
    };

    programs.zsh.shellAliases = {
      # kill emacsclient kill server alias
      ek = "emacsclient -e '(kill-emacs)'";
      # create a terminal emacs
      emt = "emacsclient -nw";
    };
  };
}
