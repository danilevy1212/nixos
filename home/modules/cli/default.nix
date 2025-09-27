{
  config,
  pkgs,
  lib,
  unstable,
  ...
}: let
  ZDOTDIR = "${config.xdg.configHome}/zsh";
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
          "??" = "ghce";
          "???" = "ghcs -t shell";
          "git?" = "ghcs -t git";
          "gh?" = "ghcs -t gh";
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
        extensions = [
          pkgs.gh-copilot
        ];
      };

      # Vibing and coding
      programs.opencode = {
        enable = true;
        rules = builtins.readFile ./opencode/RULES.md;
      };

      # NOTE  I have to use this so order of keys is respected, important for bash permissions
      xdg.configFile."opencode/opencode.json" = {
        text = ''
          {
              "$schema": "https://opencode.ai/config.json",
              "theme": "system",
              "keybinds": {
                  "session_interrupt": "<leader>esc"
              },
              "agent": {
                  "plan": {
                      "model": "anthropic/claude-opus-4-1-20250805"
                  },
                  "build": {
                      "model": "anthropic/claude-sonnet-4-20250514"
                  }
              },
              "permission": {
                  "edit": "ask",
                  "bash": {
                      "git status*": "allow",
                      "git log*": "allow",
                      "git diff*": "allow",
                      "git rev-parse*": "allow",
                      "*": "ask"
                  },
                  "webfetch": "allow"
              },
              "mcp": {
                  "atlassian": {
                      "enabled": true,
                      "type": "local",
                      "command": ["${pkgs.nodejs}/bin/npx", "-y", "mcp-remote", "https://mcp.atlassian.com/v1/sse"]
                  },
                  "gitlab": {
                      "enabled": true,
                      "type": "local",
                      "command": ["${pkgs.nodejs}/bin/npx", "-y", "@zereight/mcp-gitlab"]
                  },
                  "github": {
                      "enabled": true,
                      "type": "remote",
                      "url": "https://api.githubcopilot.com/mcp/",
                      "headers": {
                           "Authorization": "Bearer {env:GITHUB_PERSONAL_ACCESS_TOKEN}"
                      }
                  }
              }
          }
        '';
      };

      # TODO  This is required by several modules. Maybe I need a "mixins" folder.
      # Per directory environment
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      services.lorri = {
        enable = true;
      };

      # General utilities
      home.packages = with pkgs; [
        # System
        fastfetch
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

        # Docker Management
        lazydocker

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

        # TUI Browser
        browsh
      ];

      # A tldr client
      programs.tealdeer = {
        enable = true;
        settings.updates.auto_update = true;
      };
    };
  }
