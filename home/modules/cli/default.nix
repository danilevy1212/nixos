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
        rules = ''
                   # General Project Rules

                   1. **File Read Restrictions**
                      - Never read files that are ignored by git (as defined in `.gitignore` or `.git/info/exclude`).
                      - This includes sensitive files such as `.env`, credentials, and key files.
                      - Only read files that are tracked or untracked and not ignored. If you must read a file outside the current project, do it with `cat` and ask for explicit user permission.

                   2. **Git Repository Requirement**
                        - Before any file operation (read, write, edit, create, delete), the assistant must check if the current working directory is a git repository. If it is not, the assistant must ask for explicit user permission before proceeding, or abort the operation and return the error: "Error: This operation is not permitted outside a git repository."
                      - This ensures all changes are version-controlled and secure.

                   3. **File Creation Scope**
                       - Only create new files within the current working directory (CWD).
                       - Do not create files outside the CWD, including parent, system, or user directories.
                       - If you absolutely must create a file outside the CWD, first create it with `touch` and ask for explicit user permission, then you may edit it as needed.

                   4. **File Access Scope**
                      - Never read files outside the current working directory.
                      - If you must read a file outside the CWD, use a command like `cat` and always ask for explicit user permission first.

                   5. **Error Handling**
                      - If any rule is violated, abort the operation and return a clear error message.

                    6. **Examples**
                    - Do not read `/project/secret.key` if it is listed in `.gitignore`.
                    - Do not create `/tmp/newfile.txt` if the current working directory is `/project`.
                    - Do not create `/var/log/custom.log` unless you first create it with `touch` and ask for explicit user permission, then you may edit it as needed.
                    - Do not read `/etc/hosts` unless you ask for explicit permission using `cat`.

                    ## Tools

                    # Edit

                    - Always prefer atomic edits (single, unique string replacements) for file modifications.
                    - Use `replaceAll` only for explicit "refactor" or "rename" requests, or if the user grants permission after being prompted.
                    - If `replaceAll` is needed outside of "refactor"/"rename", clearly inform the user: "I'm planning on using 'replaceAll' for this edit. Can I proceed?" and only proceed if permission is granted.
        '';
      };

    # NOTE  I have to use this so order of keys is respected, important for bash permissions
      xdg.configFile."opencode/opencode.json" = {
        text = ''
          {
              "$schema": "https://opencode.ai/config.json",
              "theme": "system",
              "model": "github-copilot/gpt-4.1",
              "permission": {
                  "edit": "ask",
                  "bash": {
                      "git status*": "allow",
                      "git log*": "allow",
                      "git diff*": "allow",
                      "*": "ask"
                  },
                  "webfetch": "allow"
              },
              "mcp": {
                  "atlassian-mcp-server": {
                      "enabled": false,
                      "type": "local",
                      "command": ["${pkgs.nodejs}/bin/npx", "-y", "mcp-remote", "https://mcp.atlassian.com/v1/sse"]
                  },
                  "gitlab-mcp-server": {
                      "enabled": false,
                      "type": "local",
                      "command": ["${pkgs.nodejs}/bin/npx", "-y", "@zereight/mcp-gitlab"]
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
