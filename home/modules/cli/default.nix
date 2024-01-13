let
  ZDOTDIR = ".config/zsh";
in
  {
    config,
    pkgs,
    hostname,
    HOSTS,
    ...
  }: {
    programs.git = {
      enable = true;
      userName = "Daniel Levy Moreno";
      userEmail =
        if hostname == HOSTS.inspirion
        then "daniellevymoreno@gmail.com"
        else "dalevy@autopay.com";
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
      };
    };

    # A pretty, modern, terminal.
    programs.alacritty = {
      enable = true;
      # package = stable.alacritty;
      settings = {
        font = {
          normal = {family = "Sarasa Mono J";};
          bold = {family = "Sarasa Mono J";};
          italic = {family = "Sarasa Mono J";};
          bold_italic = {family = "Sarasa Mono J";};
          size = 10.0;
        };
        window = {
          decorations_theme_variant = "Dark";
          opacity = 0.9;
        };
        colors = {
          primary = {
            background = "#2e3440";
            foreground = "#d8dee9";
            dim_foreground = "#a5abb6";
          };
          cursor = {
            text = "#2e3440";
            cursor = "#d8dee9";
          };
          vi_mode_cursor = {
            text = "#2e3440";
            cursor = "#d8dee9";
          };
          selection = {
            text = "CellForeground";
            background = "#4c566a";
          };
          search = {
            matches = {
              foreground = "CellBackground";
              background = "#88c0d0";
            };
          };
          normal = {
            black = "#3b4252";
            red = "#bf616a";
            green = "#a3be8c";
            yellow = "#ebcb8b";
            blue = "#81a1c1";
            magenta = "#b48ead";
            cyan = "#88c0d0";
            white = "#e5e9f0";
          };
          bright = {
            black = "#4c566a";
            red = "#bf616a";
            green = "#a3be8c";
            yellow = "#ebcb8b";
            blue = "#81a1c1";
            magenta = "#b48ead";
            cyan = "#8fbcbb";
            white = "#eceff4";
          };
          dim = {
            black = "#373e4d";
            red = "#94545d";
            green = "#809575";
            yellow = "#b29e75";
            blue = "#68809a";
            magenta = "#8c738c";
            cyan = "#6d96a5";
            white = "#aeb3bb";
          };
          footer_bar = {
            background = "#434c5e";
            foreground = "#d8dee9";
          };
        };
      };
    };

    # Autocomplete
    programs.fzf = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = true;
    };

    # Nordic Terminal
    xresources.extraConfig = builtins.readFile (pkgs.fetchzip {
        url = "https://github.com/arcticicestudio/nord-xresources/archive/v0.1.0.tar.gz";
        sha256 = "1bhlhlk5axiqpm6l2qaij0cz4a53i9hcfsvc3hw9ayn75034xr93";
      }
      + "/src/nord");

    # HISTFILE
    home.sessionVariables = {
      HISTFILE = "${config.xdg.dataHome}/history";
      USER_CUSTOM_AUTOLOAD = "$HOME/${ZDOTDIR}/autoload";
    };

    # Networking utilities
    home.packages = with pkgs; [
      # System
      neofetch
      file
      rsync
      tldr
      fasd

      # output processing
      jq
      xq-xml

      # Terminal Font
      victor-mono

      # TODO Create a welcome script with all of this.
      ## Fun
      cowsay
      lolcat
      cmatrix
      fortune
      sl
      ddate
      toilet
      figlet
      cloc

      # Fake identities
      rig

      # Text To Speach
      espeak
    ];
  }
