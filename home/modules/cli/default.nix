{
  config,
  pkgs,
  lib,
  stable,
  ...
}: let
  ZDOTDIR = "${config.xdg.configHome}/zsh";
  cfg = config.userConfig.modules.cli;
  isWork = config.userConfig.isWork;
in
  with lib; {
    imports = [./opencode ./claude-code];

    options.userConfig.modules.cli = {
      enable = mkEnableOption "Enable home-manager to take over the CLI environment";
      agents = mkOption {
        type = types.submodule {
          options = {
            enable = mkEnableOption "Enable AI agents and tools";
          };
        };
      };
      git = mkOption {
        type = types.submodule {
          options = {
            userName = mkOption {
              type = types.str;
              default = "Daniel Levy";
              description = "The name to use for git commits";
            };
            userEmail = mkOption {
              type = types.str;
              description = "The email to use for git commits";
              default = "danielmorenolevy@gmail.com";
            };
            gh = mkOption {
              type = types.submodule {
                options = {
                  extraExtensions = mkOption {
                    type = types.listOf types.package;
                    default = [];
                    description = "The list of extensions to enable";
                  };
                };
              };
            };
          };
        };
      };
    };
    config = lib.mkIf cfg.enable {
      programs.git = {
        enable = true;
        package = pkgs.gitFull;
        lfs.enable = true;
        settings = {
          user = {
            name = cfg.git.userName;
            email = cfg.git.userEmail;
          };
          core = {askpass = "";};
          merge = {conflictStyle = "diff3";};
          push = {autoSetupRemote = true;};
          init = {defaultBranch = "main";};
        };
      };
      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {syntax-theme = "Nord";};
      };

      # Add custom autoloaded functions
      home.file.autoload = {
        source = ./autoload;
        target = "${ZDOTDIR}/autoload";
        recursive = true;
      };

      # Allow fontconfig to discover fonts and configurations installed through home.packages and nix-env
      fonts.fontconfig.enable = true;

      # ZSH, just as good as eshell.
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        # NOTE This is just for easier debugging.
        dotDir = ZDOTDIR;
        initContent = builtins.readFile ./zshrc;
        # NOTE  Have custom functions available throughout subshells
        envExtra = ''
          # Add all files from the autoload directory to the fpath array
          fpath+=("$USER_CUSTOM_AUTOLOAD")
          for file in "$USER_CUSTOM_AUTOLOAD"/*; do
              if [[ -f "$file" ]]; then
                  # Autoload the function
                  autoload -Uz `basename "$file"`
              fi
          done
        '';
        shellAliases = {
          ssh = "ssh_autocd";
          # colorized ls
          ls = "ls --color=auto";
          # The only way to use rsync
          rsync = "rsync -azvhP --info=progress2";
          "??" = "oce";
          "???" = "ocs";
          "git?" = "ocs -t git";
          "gh?" = "ocs -t gh";
          "docker?" = "ocs -t docker";
        };
      };

      # Autocomplete
      programs.fzf = {
        enable = true;
        enableBashIntegration = false;
        enableFishIntegration = false;
        enableZshIntegration = true;
      };

      # HISTFILE
      home.sessionVariables = {
        HISTFILE = "${config.xdg.dataHome}/history";
        USER_CUSTOM_AUTOLOAD = "${ZDOTDIR}/autoload";
        ATAC_KEY_BINDINGS = "${pkgs.atac.src}/share/atac/key-bindings.zsh";
      };

      # github cli program
      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
        };
      };

      # Per directory environment
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      services.lorri = lib.mkIf stable.stdenv.isLinux {
        enable = true;
      };

      # General utilities
      home.packages = with pkgs; [
        # Build tools
        coreutils
        gnumake
        go-task

        # System
        fastfetch
        file
        rsync
        fasd
        cloc
        unzip
        zip
        xz

        # Github actions
        act

        # Video Archiver
        yt-dlp
        imagemagick
        ffmpeg
        libwebp
        sqlite

        # output processing
        jq
        xq-xml
        ueberzugpp
        bc
        xxd
        fd
        (ripgrep.override {withPCRE2 = true;})

        # PDF processing
        poppler-utils
        ghostscript
        pdftk
        pdfgrep
        qpdf
        stable.ocrmypdf
        unpaper
        pandoc
        languagetool
        (aspellWithDicts (d: with d; [es en en-computers en-science]))
        wordnet

        # Docker Management
        lazydocker

        ## Fun
        cowsay
        lolcat
        cmatrix
        fortune
        sl
        toilet
        figlet

        # Fake identities
        rig

        # Text To Speach
        espeak

        # TUI Browser
        browsh

        # For REPL sake
        rlwrap

        # Fonts
        iosevka-bin
        sarasa-gothic
        dejavu_fonts
        symbola
        noto-fonts
        stable.noto-fonts-color-emoji
        (import ./quivera.nix {inherit pkgs;})
      ];

      # A tldr client
      programs.tealdeer = {
        enable = true;
        settings.updates.auto_update = true;
      };

      # Agents that I have to test for work
      programs.github-copilot-cli.enable = isWork;
      programs.codex.enable = isWork;
    };
  }
