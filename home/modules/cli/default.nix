{
  config,
  pkgs,
  lib,
  ...
}: let
  ZDOTDIR = ".config/zsh";
  cfg = config.userConfig.modules.cli;
in
  with lib; {
    options.userConfig.modules.cli = {
      enable = mkEnableOption "Enable home-manager to take over the CLI environment";
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
        userName = cfg.git.userName;
        userEmail = cfg.git.userEmail;
        extraConfig = {
          core = {askpass = "";};
          merge = {conflictStyle = "diff3";};
          push = {autoSetupRemote = true;};
          init = {defaultBranch = "main";};
        };
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
        initExtra = builtins.readFile ./zshrc;
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
          ssh = "TERM=xterm-256color ssh";
          # colorized ls
          ls = "ls --color=auto";
          # The only way to use rsync
          rsync = "rsync -azvhP --info=progress2";
          "'??'" = "gh copilot explain";
          "'???'" = "gh copilot suggest -t shell";
          "'git?'" = "gh copilot suggest -t git";
          "'gh?'" = "gh copilot suggest -t gh";
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
        USER_CUSTOM_AUTOLOAD = "$HOME/${ZDOTDIR}/autoload";
      };

      # github cli program
      programs.gh = {
        enable = true;
        extensions = [] ++ cfg.git.gh.extraExtensions;
      };

      # Terminal File Manager
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        # See https://yazi-rs.github.io/docs/configuration/yazi
        settings = {
          manager = {
            show_hidden = true;
            linemode = "permissions";
          };
        };
      };

      # TODO  This is required by several modules. Maybe I need a "mixins" folder.
      # Per directory environment
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      services.lorri = {enable = true;};

      # General utilities
      home.packages = with pkgs; [
        # System
        neofetch
        file
        rsync
        fasd
        cloc

        # Video Archiver
        yt-dlp

        # output processing
        jq
        xq-xml
        ueberzugpp

        ## Fun
        cowsay
        lolcat
        cmatrix
        fortune
        sl
        ddate
        toilet
        figlet

        # Fake identities
        rig

        # Text To Speach
        espeak
      ];
    };

    # A tldr client
    programs.tealdeer = {
      enable = true;
      programs.tealdeer.settings.updates.auto_update = true;
    };
  }
