{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.userConfig.modules.gui;
in {
  options.userConfig.modules.gui = with lib; {
    enable = mkEnableOption "Enable GUI";
  };
  config = lib.mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        # Let there be control over the sound!
        pulsemixer
        pavucontrol
        playerctl
        easyeffects
        crosspipe

        # xXxScReeN_SH0TSxXx
        flameshot
        simplescreenrecorder

        # Drag and Drop convenience
        dragon-drop

        # For REPL sake
        rlwrap

        # battery indicator
        acpi

        # Sunshine client for remote desktop
        moonlight-qt

        iosevka-bin
      ];

      sessionVariables = {
        # Default theme.
        GTK_THEME = "Nordic";
        # default file-browser
        FILEMANAGER = "dolphin";
        # Allow opencode to do websearches using exa
        OPENCODE_ENABLE_EXA = "1";
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
      configFile."mimeapps.list".force = true;
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

    # Batteries included terminal emulator
    programs.ghostty = {
      enable = true;
      settings = {
        # Iosevka Nerd Font primary, Sarasa Mono J fallback for CJK
        font-family = [
          "Iosevka"
          "Sarasa Mono J"
        ];
        font-size = 10;
        theme = "Nord";
        window-theme = "dark";
        background-opacity = 0.9;

        keybind = [
          # Split creation (ctrl+a leader, tmux-style)
          "ctrl+a>v=new_split:right"
          "ctrl+a>s=new_split:down"
          "ctrl+a>x=close_surface"
          "ctrl+a>z=toggle_split_zoom"
          "ctrl+a>equal=equalize_splits"

          # Split navigation (alt+hjkl, fast & conflict-free)
          "ctrl+a>h=goto_split:left"
          "ctrl+a>j=goto_split:bottom"
          "ctrl+a>k=goto_split:top"
          "ctrl+a>l=goto_split:right"

          # Split resize
          "ctrl+a>alt+h=resize_split:left,10"
          "ctrl+a>alt+l=resize_split:right,10"
          "ctrl+a>alt+k=resize_split:up,10"
          "ctrl+a>alt+j=resize_split:down,10"

          # Tab management
          "ctrl+a>c=new_tab"
          "ctrl+a>n=next_tab"
          "ctrl+a>p=previous_tab"
          "ctrl+a>1=goto_tab:1"
          "ctrl+a>2=goto_tab:2"
          "ctrl+a>3=goto_tab:3"
          "ctrl+a>4=goto_tab:4"
          "ctrl+a>5=goto_tab:5"
          "ctrl+a>comma=prompt_surface_title"

          # Prompt jumping (requires shell integration)
          "ctrl+a>bracket_left=jump_to_prompt:-1"
          "ctrl+a>bracket_right=jump_to_prompt:1"
        ];
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
