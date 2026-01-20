{
  config,
  pkgs,
  lib,
  ...
}: let
  ZDOTDIR = "${config.xdg.configHome}/zsh";
  cfg = config.userConfig.modules.cli;
in
  with lib; {
    options.userConfig.modules.cli = {
      enable = mkEnableOption "Enable home-manager to take over the CLI environment";
      isWork = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this is a work machine";
      };
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
        settings = {
          git_protocol = "ssh";
        };
        extensions = with pkgs;
          lib.optionals cfg.agents.enable [
            gh-copilot
          ];
      };

      # Vibing and coding
      programs.opencode = lib.mkIf cfg.agents.enable {
        enable = true;
        rules = builtins.readFile ./opencode/RULES.md;
      };

      xdg.configFile."opencode/opencode.jsonc" = lib.mkIf cfg.agents.enable {
        text = ''
          {
            "$schema": "https://opencode.ai/config.json",
            "theme": "nord",
            "small_model": "${
            if cfg.isWork
            then "github-copilot/claude-haiku-4.5"
            else "opencode/kimi-k2"
          }",
            "plugin": [],
            "keybinds": {
              // TODO Wait for resolution of https://github.com/sst/opencode/issues/5752
              // "session_interrupt": "<leader>esc"
            },
            "provider": {
              "opencode": {
                "models": {
                  "gpt-5.2-codex": {
                    "reasoningEffort": "high",
                    "reasoningSummary": "auto",
                    "textVerbosity": "medium",
                    "include": [
                      "reasoning.encrypted_content"
                    ]
                  }
                }
              },
              "lmstudio": {
                "npm": "@ai-sdk/openai-compatible",
                "name": "LM Studio (local)",
                "options": {
                  "baseURL": "http://127.0.0.1:1234/v1",
                  "max_tokens": 64000
                }
              }
            },
            "agent": {
              "plan": {
                "model": "${
            if cfg.isWork
            then "github-copilot/claude-opus-4.5"
            else "opencode/claude-opus-4-5"
          }"
              },
              "build": {
                "model": "${
            if cfg.isWork
            then "github-copilot/claude-sonnet-4.5"
            else "opencode/glm-4.7-free"
          }"
              },
              "execute": {
                "model": "${
            if cfg.isWork
            then "github-copilot/claude-haiku-4.5"
            else "opencode/glm-4.7-free"
          }",
                "mode": "subagent",
                "description": "Executes the plans layed out by the plan agent.",
                "prompt": "You are the Execute subagent. Carry out concrete actions delegated by the Plan agent using the shared conversation context. Do not re‑plan; follow the given steps and constraints. Respect repository rules and permissions. Be concise: state what you did, the result, and whether anything is blocked. Ask only when a blocker prevents progress. Acknowledge each delegated step after completing it before moving forward.",
                "tools": {
                  "*": true
                }
              }
            },
            "permission": {
              "edit": "ask",
              "bash": {
                 "*": "ask",
                "git status*": "allow",
                "git log*": "allow",
                "git diff*": "allow",
                "git rev-parse*": "allow",
                "grep*": "allow",
                "rg*": "allow",
                "head*": "allow",
                "gh issue view*": "allow",
                "gh search*": "allow",
                "go list*": "allow",
                "which*": "allow"
              },
              "webfetch": "allow"
            },
            "mcp": {
              "mcphub": {
                "enabled": ${builtins.toJSON (!cfg.isWork)},
                "type": "remote",
                "url": "http://10.0.0.202:3000/mcp"
              }
            }
          }
        '';
      };

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
        bc
        xxd

        # PDF processing
        poppler-utils
        ghostscript
        pdftk
        pdfgrep
        qpdf
        ocrmypdf
        unpaper

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
      ];

      # A tldr client
      programs.tealdeer = {
        enable = true;
        settings.updates.auto_update = true;
      };
    };
  }
