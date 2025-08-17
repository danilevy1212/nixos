{
  config,
  lib,
  pkgs,
  stable,
  ...
}: let

  cfg = config.userConfig.modules.gui;
in {
  options.userConfig.modules.gui = with lib; {
    enable = mkEnableOption "Enable GUI";
    work = mkOption {
      type = types.bool;
      default = false;
      description = "Enable GUI programs for work.";
    };
  };
  config = lib.mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        # File management.
        stable.spaceFM

        # Let there be control over the sound!
        pulsemixer
        pavucontrol
        playerctl
        easyeffects
        helvum

        # Control the screens!
        arandr
        xorg.xkill

        # xXxScReeN_SH0TSxXx
        flameshot
        simplescreenrecorder

        # Drag and Drop convenience
        xdragon

        # For REPL sake
        rlwrap

        # battery indicator
        acpi

        # Sunshine client for remote desktop
        moonlight-qt
      ];

      sessionVariables = {
        # Default theme.
        GTK_THEME = "Nordic";
        # default file-browser
        FILEMANAGER = "spacefm";
      };

      # Don't manage the keyboard layout.
      keyboard = null;
    };

    home.pointerCursor = {
      name = "Numix-Cursor";
      package = pkgs.numix-cursor-theme;
    };

    # Link for the LSP
    xdg = {
      mimeApps = {
        defaultApplications = {
          # Make firefox default browser
          "x-scheme-handler/http" = ["firefox.desktop"];
          "x-scheme-handler/https" = ["firefox.desktop"];
          # Make mpv default video player
          "video/x-matroska" = ["mpv.desktop"];
          # PDF reader
          "application/pdf" = ["zathura.desktop"];
        };
      };
    };

    # Make me pretty!
    gtk = with pkgs; {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
        package = papirus-icon-theme;
      };
      theme = {
        name = "Nordic";
        package = nordic;
      };
      font = {
        name = "Sarasa UI J";
        size = 10;
        package = sarasa-gothic;
      };
    };

    # Be pretty again.
    services.picom = {
      enable = true;
      backend = "glx";
      activeOpacity = 1.0;
      inactiveOpacity = 0.9;
      fade = true;
      fadeDelta = 5;
      shadow = true;
      shadowOpacity = 0.75;
      settings = {
        unredir-if-possible = true;
      };
    };

    # A pretty, modern, terminal emulator.
    programs.alacritty = {
      enable = true;
      settings = {
        # TODO  Switch to Ioveska Nerd Font + Sarasa Mono J backup (I need to switch to Kitty, alacritty doesn't support font fallback), see https://github.com/alacritty/alacritty/issues/957
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

    # Nordic Terminal
    xresources.extraConfig = builtins.readFile (pkgs.fetchzip {
        url = "https://github.com/arcticicestudio/nord-xresources/archive/v0.1.0.tar.gz";
        sha256 = "1bhlhlk5axiqpm6l2qaij0cz4a53i9hcfsvc3hw9ayn75034xr93";
      }
      + "/src/nord");

    programs.rofi = {
      enable = true;
    };
  };
}
